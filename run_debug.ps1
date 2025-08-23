$env:G_MESSAGES_DEBUG='all'
$env:GST_DEBUG='3'  # для GStreamer сообщений
./dist/bin/dino.exe 2>&1 | Tee-Object -FilePath dino_debug.log