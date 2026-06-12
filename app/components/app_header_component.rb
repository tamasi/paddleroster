# frozen_string_literal: true

# Mapea el token `{components.app-header}` de DESIGN.md: fondo
# `{colors.primary}` con el título de la pantalla y, a la derecha, el menú
# de usuario. "Configuración" solo aparece para el rol Dueño (UX-DR2).
class AppHeaderComponent < ViewComponent::Base
  def initialize(current_user:, title:)
    @current_user = current_user
    @title = title
  end
end
