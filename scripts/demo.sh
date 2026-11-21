#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"

instance="${CATSQL_INSTANCE:-catsql-analytics-demo}"
port="${CATSQL_PORT:-55442}"
if [[ ! "$instance" =~ ^catsql-[a-z0-9][a-z0-9-]*$ ]] ||
   [[ ! "$port" =~ ^[1-9][0-9]{0,4}$ ]] || ((port > 65535)); then
    echo 'Usa CATSQL_INSTANCE=catsql-nombre y un CATSQL_PORT válido.' >&2
    exit 2
fi
volume="$instance-data"
config=".catsql/$instance.env"
owner_label='io.cathub.project=catsql-analytics'
action="${1:-}"
case "$action" in
    start|stop|info|test) ;;
    *) echo 'Uso: ./scripts/demo.sh {start|stop|info|test}' >&2; exit 2 ;;
esac
if [[ "$action" == test ]]; then
    exec ./scripts/verify.sh
fi
if ! command -v podman >/dev/null || ! podman info >/dev/null; then
    echo 'Instala Podman y comprueba su estado con podman info.' >&2
    exit 1
fi

require_owner() {
    local kind="$1" name="$2"
    if [[ "$(podman "$kind" inspect --format '{{ index .Labels "io.cathub.project" }}' "$name")" != catsql-analytics ]]; then
        echo "El recurso $name no pertenece a CatSQL." >&2
        exit 1
    fi
}

# Containers store their labels under .Config, unlike named volumes.
require_container() {
    if [[ "$(podman container inspect --format '{{ index .Config.Labels "io.cathub.project" }}' "$instance")" != catsql-analytics ]]; then
        echo "El contenedor $instance no pertenece a CatSQL." >&2
        exit 1
    fi
}

wait_for_database() {
    for ((attempt = 1; attempt <= 60; attempt++)); do
        if podman exec "$instance" sh -ec '
            test "$(cat /proc/1/comm)" = postgres
            pg_isready -q -U catsql_dev -d catsql
        '; then
            return
        fi
        sleep 1
    done
    podman logs "$instance" >&2
    echo 'PostgreSQL no quedó listo en 60 segundos. Revisa los registros anteriores.' >&2
    return 1
}

database_sql() {
    podman exec -i "$instance" psql -X -v ON_ERROR_STOP=1 -U catsql_dev -d catsql "$@"
}

connection_info() {
    if ! podman container exists "$instance"; then
        echo 'Inicia primero la instancia con ./scripts/demo.sh start.' >&2
        return 1
    fi
    require_container
    printf 'Base: catsql\nUsuario: catsql_dev\nEsquemas: catdb, analytics\nDirección publicada: '
    podman container inspect --format '{{range index .HostConfig.PortBindings "5432/tcp"}}{{.HostIp}}:{{.HostPort}}{{end}}' "$instance"
    printf 'Credencial local: %s/%s (valor de POSTGRES_PASSWORD)\n' "$project_dir" "$config"
}

case "$action" in
    start)
        if ! command -v flock >/dev/null; then
            echo 'Instala util-linux para disponer del comando flock.' >&2
            exit 1
        fi
        umask 077
        if [[ -L .catsql || -L "$config" ]]; then
            echo 'Usa un directorio y un archivo local regulares para la credencial.' >&2
            exit 1
        fi
        mkdir -p .catsql
        chmod 700 .catsql
        # Keep the lock in flock, outside the process tree that starts conmon.
        if [[ "${CATSQL_DEMO_LOCKED:-}" != "$instance" ]]; then
            export CATSQL_DEMO_LOCKED="$instance"
            exec flock --close ".catsql/$instance.lifecycle.lock" "$project_dir/scripts/demo.sh" start
        fi

        if podman container exists "$instance"; then
            require_container
            if [[ "$(podman container inspect --format '{{range index .HostConfig.PortBindings "5432/tcp"}}{{.HostIp}}:{{.HostPort}}{{end}}' "$instance")" != "127.0.0.1:$port" ]]; then
                echo 'La instancia ya tiene otro puerto. Usa el puerto original u otra instancia.' >&2
                exit 1
            fi
        fi

        if podman volume exists "$volume"; then
            require_owner volume "$volume"
            if [[ ! -s "$config" ]]; then
                echo 'Falta la credencial local del volumen existente. Conserva los datos y recupera ese archivo.' >&2
                exit 1
            fi
        fi
        if [[ ! -s "$config" ]]; then
            password="$(od -An -N24 -tx1 /dev/urandom | tr -d '[:space:]')"
            printf 'POSTGRES_PASSWORD=%s\n' "$password" > "$config"
            unset password
        fi
        if [[ ! "$(cat "$config")" =~ ^POSTGRES_PASSWORD=[a-f0-9]{48}$ ]]; then
            echo 'Formato de credencial inválido. Recupera el archivo original de la instancia.' >&2
            exit 1
        fi
        chmod 600 "$config"
        podman volume create --ignore --label "$owner_label" "$volume" >/dev/null
        require_owner volume "$volume"
        if podman container exists "$instance"; then
            if [[ "$(podman container inspect --format '{{.State.Running}}' "$instance")" != true ]]; then
                if ! podman start "$instance" >/dev/null; then
                    echo "No se pudo iniciar $instance. Comprueba si TCP $port está ocupado y vuelve a intentar." >&2
                    exit 1
                fi
            fi
        else
            if ! podman run -d --name "$instance" --label "$owner_label" \
                -p "127.0.0.1:$port:5432" \
                --env-file "$config" -e POSTGRES_USER=catsql_dev -e POSTGRES_DB=catsql \
                -v "$volume:/var/lib/postgresql/data" \
                docker.io/library/postgres:17 >/dev/null; then
                echo "No se pudo crear $instance. Revisa el error del motor, libera TCP $port si está ocupado y vuelve a intentar." >&2
                exit 1
            fi
        fi
        wait_for_database
        podman exec "$instance" mkdir -p /tmp/catsql/sql
        podman cp sql/. "${instance}:/tmp/catsql/sql/."
        podman cp scripts/install.sql "${instance}:/tmp/catsql/install.sql"
        database_sql -q -1 -f /tmp/catsql/install.sql
        connection_info
        ;;
    stop)
        if podman container exists "$instance"; then
            require_container
            if [[ "$(podman container inspect --format '{{.State.Running}}' "$instance")" == true ]]; then
                podman stop "$instance" >/dev/null
            fi
        fi
        echo 'Demostración detenida. Los datos se conservan.'
        ;;
    info)
        connection_info
        ;;
esac
