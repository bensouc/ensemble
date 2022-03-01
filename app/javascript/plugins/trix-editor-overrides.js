window.addEventListener("trix-file-accept", function (event) {

  const acceptedTypes = ['image/jpeg', 'image/png'];
  // console.log() {'test'};
  if (!acceptedTypes.includes(event.file.type)) {
    event.preventDefault()
    alert("Seuls les fichiers JPEG ou PNG sont acceptés")
  }
})
