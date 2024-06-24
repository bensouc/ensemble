import { Controller } from "stimulus";

export default class extends Controller {
  // static targets = ['box','tab']

  connect() {
    console.log('WP gen pdf controller Connected')
    // console.log(this.boxTargets)
    // this.boxTargets.forEach(target => {
    //   console.log(target)
    // })
  }
  genPdf(event) {
    event.preventDefault();
    const url = event.currentTarget.href;
    const btn = event.currentTarget;
    console.log(event.currentTarget.href);

    fetch(url)
      .then(response => {
        if (response.ok) {
          const contentDisposition = response.headers.get('Content-Disposition');
          let fileName = 'file.pdf'; // Nom par défaut
          if (contentDisposition) {
            // Gérer les deux formats possibles dans Content-Disposition
            const utf8FilenameRex = /filename\*=UTF-8''(.+)/;
            const asciiFilenameRex = /filename="?(.+)"?/;
            let match = contentDisposition.match(utf8FilenameRex);
            if (match && match[1]) {
              // Décoder pour les noms de fichiers UTF-8
              fileName = decodeURIComponent(match[1]);
            } else {
              match = contentDisposition.match(asciiFilenameRex);
              if (match && match[1]) {
                // Décoder pour les noms de fichiers ASCII avec des caractères spéciaux
                fileName = decodeURIComponent(match[1]);
              }
            }
          }
          return response.blob().then(blob => ({ blob, fileName }));
        }
        throw new Error('Network response was not ok.');
      })
      .then(({ blob, fileName }) => {
        const blobUrl = window.URL.createObjectURL(blob);
        const downloadLink = document.createElement('a');
        downloadLink.href = blobUrl;
        downloadLink.setAttribute('download', fileName); // Utiliser le vrai nom du fichier
        document.body.appendChild(downloadLink);
        downloadLink.click();
        document.body.removeChild(downloadLink);
        window.URL.revokeObjectURL(blobUrl);
        this.#resetPdfBtn(btn); // Réinitialiser le bouton après le téléchargement
      })
      .catch(error => console.error('Fetch error:', error));
    }

  #resetPdfBtn(btn) {
    btn.innerHTML = `<h6>Export PDF</h6>`
  }
}
