class VotesController < ApplicationController
  before_filter :authenticate_user!

  # Election.find(3).races.first.update(vote_start_time: Time.zone.now.change(hour: 10, min: 00), vote_end_time: Time.zone.now.change(hour: 10, min: 30))
  def index
    @race = Race.find(params[:race_id])
    now = Time.zone.now

    if current_user.is_disqualified_to_vote_in_race?(@race)
      redirect_to disqualified_race_votes_path(race_id: @race)
    else
      breadcrumbs votes_breadcrumbs, "Vote"

      if now < @race.vote_start_time
        redirect_to wait_race_votes_path(race_id: @race)
      elsif now >= @race.vote_end_time
        if current_user.voted_in_race?(@race)
          redirect_to view_race_votes_path(race_id: @race)
        else
          redirect_to missed_race_votes_path(race_id: @race)
        end
      else
        @votes = current_user.votes.for_race(@race).includes(:candidacy)
        @overflow_districts = {}
      end
    end
  end

  def view
    @race = Race.find(params[:race_id])
    if current_user.is_disqualified_to_vote_in_race?(@race)
      redirect_to disqualified_race_votes_path(race_id: @race)
    else
      authorize @race, :view_vote?

      @votes = current_user.votes.for_race(@race).includes(:candidacy)

      breadcrumbs votes_breadcrumbs, "View Votes"
    end
  end

  def create
    @race = Race.find(params[:race_id])

    if current_user.is_disqualified_to_vote_in_race?(@race)
      redirect_to disqualified_race_votes_path(race_id: @race)
    else
      authorize @race, :vote?

      breadcrumbs votes_breadcrumbs, "Vote"

      user_valid = true
      vote_completion_type = VoteCompletion::VOTE_COMPLETION_TYPE_ONLINE
      if params[:voter_email]
        vote_completion_type = VoteCompletion::VOTE_COMPLETION_TYPE_PAPER
        @voter_email = params[:voter_email]
        user = User.find_by_email(params[:voter_email])

        if user
          if vote_completion = user.voted_in_race?(@race)
            user_valid = false
            @voter_email_error = "voter has already voted (#{vote_completion.vote_type})"
          end
        else
          @voter_email_error = "email not found"
          user_valid = false
        end
      else
        user = current_user
        if user.voted_in_race?(@race)
          user_valid = false
          @voter_error = "you have already voted"
        end
      end

      if params[:votes]
        @votes = params[:votes].keys.map do |candidacy_id|
          Vote.new(candidacy: Candidacy.find(candidacy_id), user: user, race: @race)
        end
      else
        @votes = []
      end

      votes_valid, @overflow_districts = @race.votes_valid?(@votes)

      if votes_valid && user_valid
        @votes.each { |vote| vote.save }
        VoteCompletion.create(race: @race, user: user, has_voted: true, vote_type: vote_completion_type)

        if params[:voter_email]
          flash[:notice] = "The vote has been recorded"
          redirect_to enter_race_votes_path(@race)
        else
          flash[:notice] = "Your votes have been recorded"
          redirect_to view_race_votes_path(@race)
        end

      else
        if params[:voter_email]
          render 'enter'
        else
          render 'index'
        end
      end
    end
  end

  def disqualified
    @race = Race.find(params[:race_id])
    authorize @race, :disqualified?
  end

  def wait
    @race = Race.find(params[:race_id])
    authorize @race, :wait?
  end

  def missed
    @race = Race.find(params[:race_id])
    authorize @race, :missed?
  end

  def tallies
    @race = Race.find(params[:race_id])
    authorize @race, :tallies?

    @tallies = @race.tally_votes

    breadcrumbs votes_breadcrumbs, "Vote"
  end

  def enter
    @race = Race.find(params[:race_id])
    authorize @race, :enter?

    @votes = []
    @overflow_districts = {}

    breadcrumbs votes_breadcrumbs, "Vote"
  end

  def delete_votes
    @race = Race.find(params[:race_id])
    authorize @race, :delete_votes?

    @race.votes.destroy_all
    @race.vote_completions.destroy_all

    redirect_to @race
  end

  private

  def votes_breadcrumbs(include_link: true)
    [@race.name, race_path(@race)]
  end
end