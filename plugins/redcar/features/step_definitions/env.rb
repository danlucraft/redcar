After("@reset-font-size") do
  Redcar.update_gui do
    Redcar::EditView.font_size = Redcar::EditView.default_font_size
  end
end