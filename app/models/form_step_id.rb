# frozen_string_literal: true

# Stand-in for ExternalIdProvider uniqueness checks (step ids live in JSON, not a DB column).
class FormStepId
  def self.exists?(*)
    false
  end
end
