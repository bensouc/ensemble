// Les figures d'un énoncé telles que l'éditeur les reconnaît : leur type de
// contenu (Figure#content_type) et l'identifiant qu'elles portent. Sans TipTap :
// blocs.js, chargé avec la page, s'en sert aussi.
export const FIGURE_TYPE = "application/vnd.ensemble.figure"
export const ZONE_TYPE = "application/vnd.ensemble.figure-zone"

export function lireJson(texte) {
  try { return JSON.parse(texte || "{}") } catch { return {} }
}

// L'identifiant de la figure d'une pièce jointe, lu dans son sgid
// (`…/Figure/zone-80x24-b10.4.8`) : le sgid est signé, pas chiffré.
export function idDeLaFigure(attachment) {
  try {
    const sgid = lireJson(attachment).sgid
    const encode = sgid.slice(0, sgid.lastIndexOf("--")).replace(/-/g, "+").replace(/_/g, "/")
    return atob(encode).match(/Figure\/([a-z0-9._-]+)/)?.[1] ?? null
  } catch {
    return null
  }
}
