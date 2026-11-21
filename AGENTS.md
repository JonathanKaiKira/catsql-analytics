# Mantenimiento de CatSQL Analytics

- Conserva los 13 objetos base de CatDB y su atribución. Identifica el commit de origen al actualizar la copia.
- Usa datos sintéticos, identificadores técnicos en inglés y README equivalentes en inglés y español.
- Después de cambiar SQL, ejecuta `./scripts/demo.sh test` y revisa las salidas de referencia. Si cambia la operación, prueba también inicio, detención y persistencia.
- Mantén los servicios en loopback, los secretos fuera de Git y la guía personal fuera de este repositorio.
- Documenta planes observados y condiciones de medición sin introducir umbrales de tiempo en CI.
