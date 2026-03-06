module GuidesHelper
  def guides_by_section
    Guide.all.group_by(&:section).sort_by { |section, _| section }
  end
end
