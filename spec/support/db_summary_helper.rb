# frozen_string_literal: true

def format_db_summary(table_name, num_rows)
  table_name_clean = table_name.tr('_', ' ')
  if table_name_clean.end_with?('ies')
    singular = "#{table_name_clean.sub(/ies\z/, '')}y"
    plural = table_name_clean
  else
    singular = table_name_clean.sub(/s\z/, '')
    plural = "#{singular}s"
  end
  label = num_rows == 1 ? singular : plural
  " #{num_rows} #{label}"
end
