import { Controller } from "@hotwired/stimulus";

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
    const btn = event.currentTarget;
    const url = btn.href;
    // Contenu d'origine capturé ici, avant que `addSpinner` ne le remplace :
    // c'est ce qu'on remettra, icône comprise. L'ordre des actions dans la vue
    // garantit que ce contrôleur passe le premier.
    const originalContent = btn.innerHTML;

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
        this.#resetPdfBtn(btn, originalContent); // Réinitialiser le bouton après le téléchargement
      })
      .catch(error => {
        // Sans ça, un export raté laissait l'engrenage tourner indéfiniment.
        this.#resetPdfBtn(btn, originalContent);
        console.error('Fetch error:', error);
      });
    }

  #resetPdfBtn(btn, originalContent) {
    btn.innerHTML = originalContent
    // `addSpinner` fige la taille en style inline pour que le bouton ne saute pas
    // pendant l'export : on la relâche, le bouton retrouve sa largeur auto.
    btn.style.removeProperty('width')
    btn.style.removeProperty('height')
  }
}
