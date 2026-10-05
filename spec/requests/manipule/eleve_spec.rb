# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Manipule, côté élève" do
  let(:enseignante) { create(:user) }
  let(:classe) { create(:classroom, user: enseignante) }
  let!(:eleve) { create(:student, classroom: classe, first_name: "Sam") }
  let(:jeton) { Manipule::ClassroomToken.pour!(classe) }
  let(:competence) { create(:manipule_skill) }

  def banque(nombre = 3)
    create_list(:manipule_problem, nombre, skill: competence)
  end

  def designer!
    Manipule::Assignment.designer!(student: eleve, skill: competence, user: enseignante)
  end

  def entrer!
    get manipule_classe_path(token: jeton.token)
    post manipule_entrer_path(token: jeton.token), params: { student_id: eleve.id }
  end

  describe "l'entrée par l'adresse de la classe" do
    it "affiche les prénoms de la classe" do
      get manipule_classe_path(token: jeton.token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sam")
    end

    it "répond 404 sur une adresse inconnue, sans divulguer quoi que ce soit" do
      get manipule_classe_path(token: "nimporte-quoi")

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include("Sam")
    end

    it "ouvre la séance de l'élève qu'on a cliqué" do
      designer!
      banque

      entrer!

      expect(response).to redirect_to(manipule_serie_path)
    end
  end

  # Le vrai risque du poste partagé : la session de l'enseignante restée
  # ouverte sur l'ordinateur du fond de la classe. L'élève n'aurait rien à
  # contourner, il taperait l'adresse d'Ensemble et il SERAIT sa maîtresse.
  describe "l'exclusion mutuelle" do
    it "déconnecte l'enseignante quand un élève entre" do
      sign_in enseignante
      get dashboard_path
      expect(response).to have_http_status(:ok)

      entrer!

      # On quitte Manipule pour écarter le garde : ce qui reste alors de la
      # session de l'enseignante, c'est-à-dire rien.
      delete manipule_quitter_path
      get dashboard_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "le garde posté dans Ensemble" do
    it "renvoie vers Manipule un élève qui remonte vers Ensemble" do
      designer!
      banque
      entrer!

      get dashboard_path

      expect(response).to redirect_to(manipule_serie_path)
    end

    it "laisse l'enseignante se reconnecter après la séance" do
      designer!
      banque
      entrer!

      get new_user_session_path

      expect(response).to have_http_status(:ok)
    end

    it "ne gêne personne tant qu'aucun élève n'est entré" do
      sign_in enseignante

      get dashboard_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "la série" do
    before do
      designer!
      banque
      entrer!
      # La série se crée au premier affichage, pas à l'entrée.
      get manipule_serie_path
    end

    it "sert un problème avec ses trois réponses" do
      get manipule_serie_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Il y a 15 pommes")
      # Le texte VISIBLE du bouton, pas seulement sa présence quelque part dans
      # la page : la première version mettait le libellé dans un attribut et
      # affichait l'identifiant, sans que la spec bronche.
      expect(response.body).to include(">8 pommes<", ">22 pommes<", ">7 pommes<")
    end

    it "félicite sur une bonne réponse, puis propose le suivant" do
      tentative = Manipule::Practice.last.attempts.first
      bonne = tentative.problem.choices.find(&:correct?)

      post manipule_repondre_path, params: { attempt_id: tentative.id, choice_id: bonne.id }

      expect(response).to redirect_to(manipule_serie_path(vu: tentative.id))
      follow_redirect!
      expect(response.body).to include("Bravo")
      expect(tentative.reload.status).to eq("correct")
    end

    it "laisse passer un élève bloqué, et ne compte pas ça comme un échec" do
      tentative = Manipule::Practice.last.attempts.first

      post manipule_repondre_path, params: { attempt_id: tentative.id, passer: "1" }

      follow_redirect!
      expect(response.body).to include("passé")
      expect(tentative.reload.status).to eq("skipped")
    end

    # Un enfant qui rafraîchit son écran ne doit pas renvoyer sa réponse.
    it "ne rejoue pas la réponse quand l'élève rafraîchit le verdict" do
      tentative = Manipule::Practice.last.attempts.first
      mauvaise = tentative.problem.choices.reject(&:correct?).first
      post manipule_repondre_path, params: { attempt_id: tentative.id, choice_id: mauvaise.id }

      2.times { get manipule_serie_path(vu: tentative.id) }

      expect(response.body).to include("Ce n'est pas ça")
      expect(tentative.reload.status).to eq("wrong")
    end

    it "mène à l'écran de fin quand tout est répondu" do
      Manipule::Practice.last.attempts.each(&:passer!)

      get manipule_serie_path

      expect(response).to redirect_to(manipule_fin_path)
      follow_redirect!
      expect(response.body).to include("C'est terminé")
      expect(Manipule::Practice.last.reload).to be_terminee
    end

    # Un élève qui ne déchiffre pas entendrait l'histoire sans jamais savoir ce
    # qu'on lui demande : la lecture doit attraper les deux.
    it "donne à lire l'énoncé, la question et chacune des trois réponses" do
      get manipule_serie_path

      expect(response.body).to include("data-m-enonce", "data-m-question")
      # L'énoncé, la question, et les trois réponses : cinq éléments à lire.
      expect(response.body.scan("data-m-lire").size).to eq(5)
      expect(response.body.scan("data-m-ecouter-un").size).to eq(3)
    end

    it "compte les réécoutes de l'énoncé" do
      tentative = Manipule::Practice.last.attempts.first

      2.times { post manipule_ecouter_path, params: { attempt_id: tentative.id } }

      expect(tentative.reload.listened_count).to eq(2)
    end

    it "refuse de répondre à la place d'un autre élève" do
      autre = create(:student, classroom: classe)
      Manipule::Assignment.designer!(student: autre, skill: competence, user: enseignante)
      serie_autre = Manipule::Practice.commencer!(student: autre, skill: competence)
      tentative_autre = serie_autre.attempts.first

      post manipule_repondre_path, params: { attempt_id: tentative_autre.id, passer: "1" }

      expect(tentative_autre.reload.status).to eq("pending")
    end
  end

  describe "quand il n'y a rien à faire" do
    it "le dit plutôt que de lever une exception, sans affectation" do
      entrer!

      get manipule_serie_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Rien à faire")
    end

    it "le dit aussi quand la banque n'a aucun problème en circulation" do
      designer!
      banque(2).each { |probleme| probleme.update!(published: false) }
      entrer!

      get manipule_serie_path

      expect(response.body).to include("Rien à faire")
    end
  end

  describe "l'audio pré-généré" do
    before do
      designer!
      banque
      entrer!
      get manipule_serie_path
    end

    def poser_audio
      probleme = Manipule::Practice.last.attempts.first.problem
      Manipule::Audio.poser!(readable: probleme, role: "enonce", texte: probleme.statement,
                             rendu: Manipule::Synthese::Rendu.new(octets: "des octets", content_type: "audio/mp4", voix: "Thomas"))
    end

    it "donne le morceau à l'élève en séance" do
      audio = poser_audio

      get manipule_audio_path(audio)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("audio/mp4")
      expect(response.body).to eq("des octets")
    end

    it "expose son adresse sur l'élément à lire" do
      audio = poser_audio

      get manipule_serie_path

      expect(response.body).to include(manipule_audio_path(audio))
    end

    it "ne le donne à personne d'autre" do
      audio = poser_audio
      delete manipule_quitter_path

      get manipule_audio_path(audio)

      expect(response).to have_http_status(:forbidden)
    end
  end

  it "renvoie vers son lien de classe l'élève qui n'est pas entré" do
    get manipule_serie_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Tu n'es pas encore entré")
  end
  describe "l'outil de manipulation" do
    before do
      designer!
      banque
      Manipule::Problem.find_each do |probleme|
        probleme.update!(tool: "jetons",
                         tool_data: { "ressource" => "pomme", "reserve" => 12,
                                      "zones" => ["Cueillies par Sam", "Sur l'arbre"] })
      end
      entrer!
    end

    it "pose la réserve et les cases nommées d'après l'énoncé" do
      get manipule_serie_path

      expect(response.body).to include("data-m-jetons")
      # L'apostrophe du nom de zone est échappée par le gabarit, et c'est ce
      # qu'on veut : ces noms viennent de l'enseignante.
      expect(response.body).to include("Cueillies par Sam").and include("Sur l&#39;arbre")
      expect(response.body.scan(/aria-label="Jeton \d+"/).size).to eq(12)
    end

    # L'outil aide l'élève à se représenter le problème ; il ne porte pas la
    # réponse, qui reste un choix. Les deux doivent coexister à l'écran.
    it "laisse les réponses en place" do
      get manipule_serie_path

      expect(response.body).to include(">8 pommes<")
    end

    it "ne pose rien quand aucun outil n'est choisi" do
      Manipule::Problem.find_each { |probleme| probleme.update!(tool: nil) }

      get manipule_serie_path

      expect(response.body).not_to include("data-m-jetons")
    end
  end

  # Un élève s'en va au milieu de sa série — la récréation sonne, on l'appelle
  # — et un autre s'assoit à sa place. Sans sortie, le second travaillerait
  # sous le nom du premier, et le suivi mentirait sur les deux.
  describe "la sortie de séance" do
    before do
      designer!
      banque
      entrer!
      # La série se crée au premier affichage, pas à l'entrée.
      get manipule_serie_path
    end

    # L'apostrophe est échappée par le gabarit, et c'est ce qu'on veut.
    it "est offerte sur l'écran de problème" do
      get manipule_serie_path

      expect(response.body).to include("Ce n&#39;est pas moi")
    end

    it "est offerte aussi sur le verdict" do
      tentative = Manipule::Practice.last.attempts.first
      post manipule_repondre_path, params: { attempt_id: tentative.id, passer: "1" }
      follow_redirect!

      expect(response.body).to include("passé").and include("Ce n&#39;est pas moi")
    end

    it "rend la main à la liste des prénoms, sans sortir de Manipule" do
      get manipule_serie_path

      delete manipule_quitter_path

      expect(response).to redirect_to(manipule_classe_path(token: jeton.token))
    end

    it "efface bien l'identité, pour que le suivant choisisse la sienne" do
      delete manipule_quitter_path

      get manipule_serie_path

      expect(response.body).to include("Tu n'es pas encore entré")
    end

    # Le cloisonnement tient : la sortie ne mène jamais vers Ensemble.
    it "ne propose aucun lien vers Ensemble" do
      get manipule_serie_path

      expect(response.body).not_to include(dashboard_path)
    end
  end

end
