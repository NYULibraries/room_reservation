class RoomsDecorator
  attr_accessor :rooms_search

  def initialize(rooms_search)
    @rooms_search = rooms_search
  end

  extend Forwardable
  def_delegators :@rooms_search, :current_page, :total_pages, :limit_value, :results

  def find_reservations_by_range(start_dt, end_dt)
    start_dt = start_dt.to_datetime.change(:offset => "+0000")
    end_dt = end_dt.to_datetime.change(:offset => "+0000")
    rooms = self.results
    ActiveSupport::JSON::Encoding.time_precision = 0
    query =
    {
      query: {
        constant_score: {
          filter: {
            bool: {
              must: [
                { terms: { room_id: rooms.map {|r| r.id.to_i } } },
                { term: { deleted: false } },
                { bool:
                  {
                    should: [
                      {
                        bool: {
                          must: [
                            { range: { start_dt: { gte: start_dt } } },
                            { range: { start_dt: { lt: end_dt } } }
                          ]
                        }
                      },
                      {
                        bool: {
                          must: [
                            { range: { end_dt: { gt: start_dt } } },
                            { range: { end_dt: { lte: end_dt } } }
                          ]
                        }
                      },
                      {
                        bool: {
                          must: [
                            { range: { start_dt: { lte: start_dt } } },
                            { range: { end_dt: { gte: end_dt } } }
                          ]
                        }
                      }
                    ]
                  }
                }
              ]
            }
          }
        }
      },
      size: 200
    }
    reservations = Reservation.search(query)

    # Create an array of results from elasticsearch, grouped by room id
    #
    # = Example
    #   [{'room_id' => [Result, ... ]}]
    return reservations.results.group_by(&:room_id).map{|k,v| {k => v.map{|r| r}}}
  end

end
