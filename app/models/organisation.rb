class Organisation < ApplicationRecord
  has_paper_trail

  has_many :groups
  has_many :group_forms, through: :groups
  has_many :users

  has_many :mou_signatures
  has_many :organisation_domains, dependent: :destroy

  scope :not_closed, -> { where(closed: false) }
  scope :with_users, -> { joins(:users).distinct.order(:name) }

  scope :by_name, lambda { |name|
    if name.present?
      where("lower(name) LIKE :search OR lower(abbreviation) LIKE :search",
            search: "%#{sanitize_sql_like(name.downcase)}%")
    end
  }

  scope :by_mou_signed, lambda { |mou_signed|
    case mou_signed
    when "true"
      joins(:mou_signatures).distinct
    when "false"
      where.missing(:mou_signatures)
    end
  }

  def name_with_abbreviation
    if abbreviation.present? && abbreviation != name
      "#{name} (#{abbreviation})"
    else
      name
    end
  end

  def admin_users
    users.organisation_admin
  end

  alias_method :organisation_admin_users, :admin_users

  def as_json(options = {})
    options[:only] ||= %i[id name]
    options[:methods] ||= %i[organisation_admin_users]
    super(options)
  end
end
