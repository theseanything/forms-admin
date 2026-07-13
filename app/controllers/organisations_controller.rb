class OrganisationsController < WebController
  include Pagy::Backend

  after_action :verify_authorized

  def index
    authorize Organisation, :can_view_organisations?

    @filter_input = Organisations::FilterInput.new(filter_params)

    @pagy, @organisations = pagy(filtered_organisations, limit: 50)

    organisation_ids = @organisations.map(&:id)
    @user_counts = User.where(organisation_id: organisation_ids).group(:organisation_id).count
    @form_counts = GroupForm.joins(:group).where(groups: { organisation_id: organisation_ids }).reorder(nil).group("groups.organisation_id").count
    @agreement_types = MouSignature.where(organisation_id: organisation_ids)
                                   .distinct
                                   .pluck(:organisation_id, :agreement_type)
                                   .group_by(&:first)
                                   .transform_values { |pairs| pairs.map(&:last).sort }
  end

  def show
    authorize Organisation, :can_view_organisations?

    @organisation = Organisation.includes(:organisation_domains, mou_signatures: :user).find(params[:id])
  end

private

  def filtered_organisations
    scope = Organisation
      .by_name(filter_params[:name])
      .by_agreement_type(filter_params[:agreement_type])

    apply_sort(scope)
  end

  def apply_sort(scope)
    case filter_params[:sort]
    when "users"
      scope.order_by_user_count
    when "forms"
      scope.order_by_form_count
    else
      scope.order(:name)
    end
  end

  def filter_params
    params[:filter]&.permit(:name, :agreement_type, :sort) || {}
  end
end
