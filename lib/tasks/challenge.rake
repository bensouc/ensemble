namespace :challenge do
  desc "Identifie les challenges avec des images cassées dans leur contenu Action Text"
  task check_broken_images: :environment do
    broken_challenges = []

    puts "Vérification des images attachées dans les challenges..."

    # Définir la méthode url_accessible? dans le contexte de la tâche
    #

    def url_accessible?(url)
      require "net/http"
      uri = URI.parse(url)
      stop = false
      # Effectuer une requête HTTP GET
      until stop
        response = nil
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
          request = Net::HTTP::Get.new(uri)
          response = http.request(request)
        end

        break if response.code.to_i == 200

        new_uri = response["location"]
        break if new_uri.to_s == url
        # p url
        # p new_uri
        # puts "Redirection vers : #{new_uri}"
        uri = URI.parse(new_uri)
      end

      # Considérer les codes 200, 301, et 302 comme valides
      valid_statuses = [200]
      puts "Vérification de l'URL: #{url}, Statut: #{response.code}"
      valid_statuses.include?(response.code.to_i)
    rescue StandardError => e
      puts "Erreur lors de la vérification de l'URL: #{url}, Erreur: #{e.message}"
      false
    end

    # Liste des écoles de l'application
    puts "#" * 20
    puts "Parmi les écoles de l'application : pour laquelle souhaitez-vous tester les images ?"
    School.all.each do |school|
      puts "#{school.id} - #{school.name}"
    end
    puts "#" * 20
    puts 'Tapez "all" pour toutes les écoles'
    puts 'Tapez "none" pour aucune école'
    puts "Ou tapez l'ID de l'école"
    puts 'Tapez "exit" pour quitter'
    school_id = STDIN.gets.chomp

    # Sélection des challenges en fonction de l'entrée utilisateur
    if school_id == "exit"
      puts "Au revoir !"
      exit
    elsif school_id == "none"
      puts "Aucune école sélectionnée. Vérification de toutes les écoles..."
      challenges = Challenge.all
    elsif school_id == "all"
      puts "Vérification de toutes les écoles..."
      challenges = Challenge.all
    else
      school = School.find_by(id: school_id)
      users = school.users
      challenges = Challenge.where(user_id: users.pluck(:id).uniq)
    end

    puts "#" * 20

    # Vérification des images dans les challenges sélectionnés
    challenges.find_each do |challenge|
      # Extraire le contenu HTML du body
      content_html = challenge.content.body.to_s

      # Rechercher toutes les balises <action-text-attachment>
      attachments = content_html.scan(/<action-text-attachment[^>]*>/)

      attachments.each do |attachment|
        # Extraire l'URL de l'image depuis l'attribut `url`
        if attachment =~ /url="([^"]+)"/
          url = Regexp.last_match(1)

          # Vérifier si l'URL est accessible
          unless url_accessible?(url)
            puts "Image cassée trouvée dans le Challenge ID: #{challenge.id}, Nom: #{challenge.name}, URL: #{url}"
            broken_challenges << challenge
          end
        else
          puts "Aucune URL trouvée dans l'attachement pour le Challenge ID: #{challenge.id}, Nom: #{challenge.name}"
        end
      end
    rescue StandardError => e
      puts "Erreur lors de la vérification du Challenge ID: #{challenge.id}, Nom: #{challenge.name}"
      puts "Erreur: #{e.message}"
      broken_challenges << challenge
    end

    # Afficher les résultats
    if broken_challenges.any?
      puts "\nListe des challenges avec des images cassées :"
      broken_challenges.each do |challenge|
        puts "ID: #{challenge.id}, Nom: #{challenge.name}"
      end
      puts "\nTotal des challenges avec des images cassées : #{broken_challenges.count}"
      puts "Total des challenges vérifiés : #{challenges.count}"
      puts "Pourcentage de succès : #{((challenges.count - broken_challenges.count) / challenges.count.to_f * 100).round(2)}%"
    else
      puts "Aucune image cassée trouvée dans les challenges."
    end
  end
end
