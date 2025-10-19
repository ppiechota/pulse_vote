defmodule PulseVoteWeb.UserSessionHTML do
  use PulseVoteWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:pulse_vote, PulseVote.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
