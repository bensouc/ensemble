import { StreamActions } from "@hotwired/turbo";

// Rouvrir le dossier d'une compétence après un transfert.
//
// Les exercices sont rangés dans des dossiers repliables. Après un
// déplacement, l'exercice atterrit dans le dossier d'arrivée — fermé la
// plupart du temps : on ne voyait pas où il était allé, et le dossier de
// départ pouvait se retrouver refermé lui aussi.
//
// On délègue au contrôleur Stimulus qui tient déjà cet état plutôt que de
// manipuler ses classes de l'extérieur : `openList` n'ouvre que si c'est
// fermé, et ne referme jamais.
StreamActions.ouvrir_dossier = function () {
  const dossier = document.getElementById(this.getAttribute("cible"));
  if (!dossier) return;

  window.Stimulus?.getControllerForElementAndIdentifier(dossier, "wp-by-student")?.openList();
};
