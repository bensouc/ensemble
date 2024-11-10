module PdfGenerator
  class Base
    def initialize(layout = "pdf.html")
      @layout = layout
    end
    # Méthode abstraite qui sera implémentée par les classes dérivées
    def generate
      raise NotImplementedError, "Vous devez implémenter la méthode `generate` dans une classe dérivée"
    end
  end
end
