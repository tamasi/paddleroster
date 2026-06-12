# frozen_string_literal: true

# Mapea el token `{components.bottom-nav}` de DESIGN.md: navegación fija con
# Inicio, Calendario y Pagos para todos los roles, y Reportes solo para
# Dueño (UX-DR2, FR-12). El orden no cambia entre roles, solo la cantidad
# de ítems.
class BottomNavComponent < ViewComponent::Base
  def initialize(current_user:, current_path:)
    @current_user = current_user
    @current_path = current_path
  end

  def items
    items = [
      { label: "Inicio", path: helpers.root_path },
      { label: "Calendario", path: helpers.calendario_path },
      { label: "Pagos", path: helpers.pagos_path }
    ]
    items << { label: "Reportes", path: helpers.reportes_path } if @current_user&.owner?
    items
  end

  def active?(item)
    item[:path] == @current_path
  end

  def item_classes(item)
    active?(item) ? "text-primary dark:text-primary-dark" : "text-text-secondary dark:text-text-secondary-dark"
  end
end
