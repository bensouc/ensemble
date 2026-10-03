# frozen_string_literal: true

require "rails_helper"

RSpec.describe GenerateResultsClassroomPdfsJob, type: :job do
  let(:user) { create(:user) }
  let(:classroom) { create(:classroom, user:) }

  before { create(:student, classroom:) }

  # La file pdf a son worker à un seul thread (config/queue.yml).
  it "part dans la file pdf" do
    expect { described_class.perform_later(classroom, user.id) }.
      to have_enqueued_job(described_class).on_queue("pdf")
  end

  # Sous Sidekiq, la relance était implicite ; sous Solid Queue, elle vient
  # d'ApplicationJob.
  it "se remet en file après une panne passagère de Chrome" do
    allow(PdfGenerator::StudentResultPdf).to receive(:new).and_raise(Ferrum::TimeoutError)

    expect { described_class.perform_now(classroom, user.id) }.
      to have_enqueued_job(described_class).with(classroom, user.id)
  end

  it "abandonne si la classe a disparu entre-temps" do
    donnees = described_class.new(classroom, user.id).serialize
    donnees["arguments"][0]["_aj_globalid"] = "gid://ensemble/Classroom/0"

    expect { ActiveJob::Base.execute(donnees) }.not_to have_enqueued_job(described_class)
  end
end
