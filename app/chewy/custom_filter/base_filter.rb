
class Chewy::CustomFilter::BaseFilter
  private
  def must_query query
    {must: query}
  end
  def must_not_query query
    {must_not: query}
  end
  def should_query query
    {should: query}
  end
  def term_query field, value
    {term: {field => value}}
  end
  def match_query field, value
    {match: {field => value}}
  end
  def match_phrase_query field, value
    {match_phrase: {field => value}}
  end
  def parse_date date
    Date.strptime(date, Settings.format_date.dd_mm_yyyy)
  rescue StandardError
    nil
  end

  def multi_match keyword
    {multi_match: {query: keyword}}
  end
end
