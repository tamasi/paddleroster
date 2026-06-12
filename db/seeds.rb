# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

if Rails.env.development?
  complejo_piloto = Complejo.find_or_create_by!(name: "Complejo Piloto")

  admin = User.find_or_create_by!(email_address: "admin@retroai.test") do |user|
    user.password = "password123"
    user.password_confirmation = "password123"
    user.role = :owner
    user.complejo = complejo_piloto
  end
  admin.update!(role: :owner) unless admin.owner?
  admin.update!(complejo: complejo_piloto) unless admin.complejo == complejo_piloto

  puts "Creando canchas piloto..."
  [
    { name: "Cancha 1 (Pádel)", sport: :padel },
    { name: "Cancha 2 (Pádel)", sport: :padel },
    { name: "Cancha 3 (Pádel)", sport: :padel },
    { name: "Cancha 4 (Pádel)", sport: :padel },
    { name: "Cancha 5 (Pádel)", sport: :padel },
    { name: "Fútbol 5 - A", sport: :futbol_5 },
    { name: "Fútbol 5 - B", sport: :futbol_5 }
  ].each do |cancha_attrs|
    complejo_piloto.canchas.find_or_create_by!(name: cancha_attrs[:name]) do |cancha|
      cancha.sport = cancha_attrs[:sport]
    end
  end
end
