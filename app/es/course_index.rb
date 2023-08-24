class Es::CourseIndex
  index_scope Course.includes(:categories, :instructors, :level, :attendees, :general_setting, :target_positions)
  field :vi_title, fields: {raw: {type: :keyword}}, value: (lambda do |course|
    Utils::ConvertCharacter.convert_vi_char(course.title)
  end)
  field :ja_title, type: :text, analyzer: :ja_analyzer, fields: {raw: {type: :keyword}}, value: (lambda do |course|
    course.title
  end)
  field :status, type: :integer, value: ->(course){Course.statuses[course.status]}
  field :categories do
    field :vi_name, fields: {raw: {type: :keyword}}, value: (lambda do |cate|
      Utils::ConvertCharacter.convert_vi_char(cate.name)
    end)
    field :ja_name, type: :text, fields: {raw: {type: :keyword}},
      analyzer: :ja_analyzer, value: (lambda do |cate|
                                        cate.name
                                      end)
  end
  field :instructors do
    field :vi_name, fields: {raw: {type: :keyword}}, value: (lambda do |instructor|
      Utils::ConvertCharacter.convert_vi_char(instructor.name)
    end)
    field :ja_name, type: :text, fields: {raw: {type: :keyword}},
      analyzer: :ja_analyzer, value: (lambda do |instructor|
                                        instructor.name
                                      end)
  end
  field :vi_level_name, fields: {raw: {type: :keyword}}, value: (lambda do |course|
    Utils::ConvertCharacter.convert_vi_char(course.level&.name)
  end)
  field :ja_level_name, type: :text, analyzer: :ja_analyzer,
    fields: {raw: {type: :keyword}}, value: (lambda do |course|
                                               course.level&.name
                                             end)
  field :updated_at, type: :date
  field :num_of_accepted_register, type: :integer, value: (lambda do |course|
    course.attendees.joined_course.size
  end)
  field :start_date, type: :date, value: (lambda do |course|
    course.general_setting&.time_start_publish&.to_date
  end)
  field :course_type, type: :integer, value: (lambda do |course|
    Course.course_types[course.course_type]
  end)
  field :have_certificate, type: :boolean, value: (lambda do |course|
    course.have_certificate
  end)
  field :require_agreement, type: :boolean, value: (lambda do |course|
    course.require_agreement
  end)
  field :vi_province_name, fields: {raw: {type: :keyword}}, value: (lambda do |course|
    Utils::ConvertCharacter.convert_vi_char(course.province&.name)
  end)
  field :ja_province_name, type: :text, analyzer: :ja_analyzer,
    fields: {raw: {type: :keyword}}, value: (lambda do |course|
                                               course.province&.name
                                             end)
  field :start_at, type: :date, value: (lambda do |course|
    course.schedules.minimum(:start_at)&.to_date
  end)
  field :avg_rating, type: :float, value: (lambda do |course|
    course.avg_rating
  end)
  field :language, type: :integer, value: ->(course){Course.languages[course.language]}
  field :target_positions do
    field :vi_name, fields: {raw: {type: :keyword}}, value: (lambda do |position|
      Utils::ConvertCharacter.convert_vi_char(position.name)
    end)
    field :ja_name, type: :text, fields: {raw: {type: :keyword}},
      analyzer: :ja_analyzer, value: (lambda do |position|
                                        position.name
                                      end)
  end
end