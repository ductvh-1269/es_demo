class CourseFilter < BaseFilter
  MAX_LENGTH_OF_TITLE_FOR_HEADER = 150
  MAX_LENGTH_OF_TITLE_FOR_MANAGER = 255
  DEFAULT_PAGE = 1
  KEYWORD_REGEX = %r{[-._!"`'#%&,:;<>=@{}~$()*+/\\?\[\]^|]}
  # rubocop:disable Metrics/AbcSize
  def initialize options = {}
    super()
    @is_manager = options[:is_manager]
    max_length = is_manager ? MAX_LENGTH_OF_TITLE_FOR_MANAGER : MAX_LENGTH_OF_TITLE_FOR_HEADER
    @keyword_by_course = options[:keyword_by_course].to_s[0...max_length].strip.squeeze(" ")
    @keyword_by_course_after_convert = convert_vi_keyword(keyword_by_course).gsub(KEYWORD_REGEX, " ")
    @keyword_by_category = convert_vi_keyword(options[:keyword_by_category].to_s[0...max_length])
                           .gsub(KEYWORD_REGEX, " ").strip.squeeze(" ")
    @keyword_by_instructor = convert_vi_keyword(options[:keyword_by_instructor].to_s[0...max_length])
                             .gsub(KEYWORD_REGEX, " ").strip.squeeze(" ")
    @keyword_by_level = convert_vi_keyword(options[:keyword_by_level].to_s[0...max_length])
                        .gsub(KEYWORD_REGEX, " ").strip.squeeze(" ")
    @order = options[:order]
    @category_names = options[:category_names]
    @instructor_names = options[:instructor_names]
    @statuses = options[:statuses]
    @start_dates = options[:start_dates]
    @course_types = options[:course_types]
    @level_names = options[:level_names]
    @languages = options[:languages]
    @have_certificate = options[:have_certificate]
    @require_agreement = options[:require_agreement]
    @province_names = options[:province_names]
    @starting_from = options[:starting_from]
    @starting_to = options[:starting_to]
    @avg_rating = options[:avg_rating]
    @must_query = []
    @must_not_query = []
    @limit = (options[:items] || Settings.pagy.default_item_20).to_i
    @page = (options[:page] || DEFAULT_PAGE).to_i
    @course_ids = options[:course_ids] || []
    @position_names = options[:position_names]
  end
  # rubocop:enable Metrics/AbcSize
  def filter
    return @filter if @filter
    data = CoursesIndex.limit(@limit).offset(offset).query(query).order(order_query)
    @pagination = pagy_pagination data.total_count
    @filter = data.map{|record| record}
  end
  def filter_ids
    filter.map{|record| record.attributes["id"].to_i}
  end
  attr_reader :pagination
  private
  attr_reader :keyword_by_course, :order, :must_query, :category_names, :instructor_names,
              :level_names, :is_manager, :statuses, :start_dates, :course_types, :languages, :must_not_query,
              :keyword_by_category, :keyword_by_instructor, :keyword_by_level, :course_ids,
              :keyword_by_course_after_convert,
              :have_certificate, :require_agreement, :province_names, :starting_from, :starting_to,
              :avg_rating, :position_names
  def query
    build_query
    build_must_not_query
    {
      bool: {
        must: must_query,
        must_not: must_not_query
      }
    }
  end
  def build_query
    ids_must_query
    is_manager ? statuses_must_query : publish_status_query
    keyword_must_query
    category_names_must_query
    instructor_names_must_query
    course_types_must_query
    level_names_must_query
    languages_must_query
    have_certificate_must_query
    require_agreement_must_query
    province_names_must_query
    starting_time_must_query
    avg_rating_must_query
    target_positions_must_query
  end
  def build_must_not_query
    statuses_must_not_query if is_manager
  end
  def statuses_must_not_query
    return if !statuses.is_a?(Array) || convert_start_dates.blank? || statuses.present?
    must_not_query << match_phrase_query(:status, Course.statuses[:draft])
    must_query << {bool: {should: start_dates_must_query}}
  end
  def publish_status_query
    must_query << term_query(:status, Course.statuses[:publish])
  end
  def keyword_must_query
    build_keyword_query = if keyword_by_course.present?
                            fields_query = [:ja_title_course]
                            fields_query << :vi_title_course if keyword_by_course_after_convert.present?
                            fields_query.map do |field|
                              {
                                bool: {
                                  must: send("#{field}_must_query")
                                }
                              }
                            end
                          elsif keyword_by_category.present?
                            %i(keyword_by_vi_category_name keyword_by_ja_category_name).map do |field|
                              {
                                bool: {
                                  must: send("#{field}_must_query"),
                                  filter: [
                                    script: {
                                      script: {
                                        inline: script_access_query("categories.vi_name.raw"),
                                        lang: :painless,
                                        params: {
                                          keywords: keyword_by_category.split(" ")
                                        }
                                      }
                                    }
                                  ]
                                }
                              }
                            end
                          elsif keyword_by_instructor.present?
                            %i(keyword_by_vi_instructor_name keyword_by_ja_instructor_name).map do |field|
                              {
                                bool: {
                                  must: send("#{field}_must_query"),
                                  filter: [
                                    script: {
                                      script: {
                                        inline: script_access_query("instructors.vi_name.raw"),
                                        lang: :painless,
                                        params: {
                                          keywords: keyword_by_instructor.split(" ")
                                        }
                                      }
                                    }
                                  ]
                                }
                              }
                            end
                          elsif keyword_by_level.present?
                            %i(keyword_by_vi_level_name keyword_by_ja_level_name).map do |field|
                              {
                                bool: {
                                  must: send("#{field}_must_query")
                                }
                              }
                            end
                          else
                            []
                          end
    must_query << {bool: {should: build_keyword_query}}
  end


  def vi_title_course_must_query
    keyword_by_course_after_convert.split(" ").map do |char|
      match_phrase_query(:vi_title, char)
    end
  end



  def ja_title_course_must_query
    [match_phrase_query(:ja_title, keyword_by_course)]
  end
  def keyword_by_vi_category_name_must_query
    keyword_by_category.split(" ").map do |char|
      match_query("categories.vi_name", char)
    end
  end
  def keyword_by_ja_category_name_must_query
    [match_phrase_query("categories.ja_name", keyword_by_category)]
  end
  def keyword_by_vi_instructor_name_must_query
    keyword_by_instructor.split(" ").map do |char|
      match_query("instructors.vi_name", char)
    end
  end
  def keyword_by_ja_instructor_name_must_query
    [match_phrase_query("instructors.ja_name", keyword_by_instructor)]
  end
  def keyword_by_vi_level_name_must_query
    keyword_by_level.split(" ").map do |char|
      match_query(:vi_level_name, char)
    end
  end
  def keyword_by_ja_level_name_must_query
    [match_phrase_query(:ja_level_name, keyword_by_level)]
  end
  def convert_vi_keyword keyword
    Utils::ConvertCharacter.convert_vi_char(keyword)
  end
  
def category_names_must_query
    return if !category_names.is_a?(Array) || category_names.blank?
    convert_vi_category_names = category_names.map do |category_name|
      convert_vi_keyword(category_name)
    end
    category_names_should_query = convert_vi_category_names.map do |name|
      term_query("categories.vi_name.raw", name)
    end
    must_query << {bool: {should: category_names_should_query}}
  end




  def instructor_names_must_query
    return if !instructor_names.is_a?(Array) || instructor_names.blank?
    convert_vi_instructor_names = instructor_names.map do |instructor_name|
      convert_vi_keyword(instructor_name)
    end
    instructor_names_should_query = convert_vi_instructor_names.map do |name|
      term_query("instructors.vi_name.raw", name)
    end
    must_query << {bool: {should: instructor_names_should_query}}
  end
  def statuses_must_query
    return if !statuses.is_a?(Array) || statuses.blank?
    statuses_should_query = statuses.map(&:to_i).map do |status|
      if status.in? Course.statuses.slice(:publish, :close).values
        {
          bool: {
            must: [
              match_phrase_query(:status, status),
              start_dates_must_query
            ].compact
          }
        }
      else
        match_phrase_query(:status, status)
      end
    end
    must_query << {bool: {should: statuses_should_query}}
  end
  def course_types_must_query
    return if !course_types.is_a?(Array) || course_types.blank?
    course_types << Course.course_types["scorm"].to_s if course_types.include? Course.course_types["online"].to_s
    course_types_should_query = course_types.map(&:to_i).uniq.map do |course_type|
      match_phrase_query(:course_type, course_type)
    end
    must_query << {bool: {should: course_types_should_query}}
  end
  def start_dates_must_query
    start_dates_should_query = convert_start_dates.map do |start_date|
      match_phrase_query(:start_date, start_date)
    end
    {bool: {should: start_dates_should_query}}
  end
  def level_names_must_query
    return if !level_names.is_a?(Array) || level_names.blank?
    convert_vi_level_names = level_names.map do |level_name|
      convert_vi_keyword(level_name)
    end
    level_names_should_query = convert_vi_level_names.map do |name|
      term_query("vi_level_name.raw", name)
    end
    must_query << {bool: {should: level_names_should_query}}
  end
  def languages_must_query
    return if !languages.is_a?(Array) || languages.blank?
    languages_should_query = languages.map(&:to_i).map do |language|
      match_phrase_query(:language, language)
    end
    must_query << {bool: {should: languages_should_query}}
  end
  def target_positions_must_query
    return if !position_names.is_a?(Array) || position_names.blank?
    convert_vi_position_names = position_names.map do |position_title|
      convert_vi_keyword(position_title)
    end
    position_names_should_query = convert_vi_position_names.map do |name|
      term_query("target_positions.vi_name.raw", name)
    end
    must_query << {bool: {should: position_names_should_query}}
  end
  def have_certificate_must_query # rubocop:disable Naming/PredicateName
    return if %w(true false).exclude? have_certificate
    must_query << term_query(:have_certificate, have_certificate)
  end
4:49
def require_agreement_must_query
    return if %w(true false).exclude? require_agreement
    must_query << term_query(:require_agreement, require_agreement)
  end
  def province_names_must_query
    return if !province_names.is_a?(Array) || province_names.blank?
    convert_vi_province_names = province_names.map do |province|
      convert_vi_keyword(province)
    end
    province_names_should_query = convert_vi_province_names.map do |name|
      term_query("vi_province_name.raw", name)
    end
    must_query << {bool: {should: province_names_should_query}}
  end
  def starting_time_must_query
    return if starting_from.blank? && starting_to.blank?
    from_month, from_year = extract_month_and_year starting_from
    to_month, to_year = extract_month_and_year starting_to
    gte = case [from_month.present?, from_year.present?]
          when [true, true]
            "#{from_year}-#{from_month}-01"
          when [false, true]
            "#{from_year}-01-01"
          when [false, false]
            nil
          end
    lte = case [to_month.present?, to_year.present?]
          when [true, true]
            "#{to_year}-#{to_month}-#{DateTime.new(to_year.to_i, to_month.to_i).end_of_month.day}"
          when [false, true]
            "#{to_year}-12-31"
          when [false, false]
            now = Date.current
            "#{now.year}-#{now.strftime('%m')}-#{now.end_of_month.day}"
          end
    starting_time_query = {range: {start_at: {gte:, lte:}}}
    must_query << starting_time_query
  end
  def extract_month_and_year mm_yyyy
    return [] unless mm_yyyy
    mm_yyyy.include?("/") ? mm_yyyy.split("/") : [nil, mm_yyyy]
  end
  def avg_rating_must_query
    return if avg_rating.blank?
    gte, lte = avg_rating.split("-")
    must_query << {range: {avg_rating: {gte:, lte:}}}
  end
  def convert_start_dates
    return [] if !start_dates.is_a?(Array) || start_dates.blank?
    start_dates.map{|start_date| parse_date(start_date)}.compact
  end
  def order_query
    case order
    when Settings.courses.orders.alphabet_asc
      [{"vi_title.raw" => {"order" => "asc"}}, {"ja_title.raw" => {"order" => "asc"}}]
    when Settings.courses.orders.alphabet_desc
      [{"vi_title.raw" => {"order" => "desc"}}, {"ja_title.raw" => {"order" => "desc"}}]
    when Settings.courses.orders.recently_updated_asc
      [{"updated_at" => {"order" => "asc"}}]
    when Settings.courses.orders.recently_updated_desc
      [{"updated_at" => {"order" => "desc"}}]
    when Settings.courses.orders.by_num_of_register_asc
      [{"num_of_accepted_register" => {"order" => "asc"}}]
    when Settings.courses.orders.by_num_of_register_desc
      [{"num_of_accepted_register" => {"order" => "desc"}}]
    else
      [{"vi_title.raw" => {"order" => "asc"}}, {"ja_title.raw" => {"order" => "asc"}}]
    end
  end
  def ids_must_query
    must_query << {bool: {must: [{ids: {values: course_ids}}]}}
  end
  def pagy_pagination total_count
    {
      items: @limit,
      count: total_count,
      page: @page,
      pages: (total_count / @limit).to_i
    }
  end
  def offset
    (@page - 1) * @limit
  end
  def script_access_query field
    <<-SQL
      def is_keyword_valids = new ArrayList();
      for (key in doc['#{field}']) {
        boolean is_keyword_valid;
        for (kw in params.keywords) {
          if(key.contains(kw)) {
            is_keyword_valid = true;
          } else {
            is_keyword_valid = false;
            break;
          }
        }
        is_keyword_valids.add(is_keyword_valid);
      }
      if (is_keyword_valids.contains(true)) {
        return true;
      }
      return false;
    SQL
  end
end