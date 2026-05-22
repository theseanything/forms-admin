# frozen_string_literal: true

require "rails_helper"

RSpec.describe FormDocument::LocaleProjection do
  let(:content) do
    {
      "form_id" => "1",
      "name" => { "en" => "English name", "cy" => "Welsh name" },
      "steps" => [
        {
          "id" => "step-1",
          "type" => "question",
          "position" => 1,
          "question_text" => { "en" => "Question?", "cy" => "Cwestiwn?" },
          "hint_text" => { "en" => "" },
          "page_heading" => { "en" => "" },
          "guidance_markdown" => { "en" => "" },
          "answer_type" => "text",
          "routing_conditions" => [],
          "data" => { "is_optional" => false, "is_repeatable" => false },
        },
      ],
    }
  end

  it "projects English strings for runner API" do
    projected = described_class.project(content, language: "en")
    expect(projected["name"]).to eq("English name")
    expect(projected["steps"].first["question_text"]).to eq("Question?")
    expect(projected["language"]).to eq("en")
  end

  it "projects Welsh strings when requested" do
    projected = described_class.project(content, language: "cy")
    expect(projected["name"]).to eq("Welsh name")
    expect(projected["steps"].first["question_text"]).to eq("Cwestiwn?")
    expect(projected["language"]).to eq("cy")
  end
end
