# frozen_string_literal: true

require 'legion/extensions/jira/helpers/client'

module Legion
  module Extensions
    module Jira
      module AuditRecords
        module Runners
          module AuditRecords
            include Legion::Extensions::Jira::Helpers::Client

            def get_audit_records(offset: 0, limit: 1000, filter: nil, from: nil, to: nil, **)
              params = { offset: offset, limit: limit }
              params[:filter] = filter if filter
              params[:from] = from if from
              params[:to] = to if to
              resp = connection(**).get('/rest/api/3/auditing/record', params)
              { records: resp.body }
            end

            include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers, false) &&
                                                        Legion::Extensions::Helpers.const_defined?(:Lex, false)
          end
        end
      end
    end
  end
end
