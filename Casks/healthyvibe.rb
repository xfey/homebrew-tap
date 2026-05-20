cask "healthyvibe" do
  version "1.0.2"
  sha256 "824df7d216ef637fea2696f6371a4e7312afd0bf3c1a01e919ab5b00ffacd31d"

  url "https://github.com/xfey/HealthyVibe/releases/download/v1.0.2/HealthyVibe-1.0.2.zip"
  name "HealthyVibe"
  desc "Menu bar health breaks for AI coding waits"
  homepage "https://github.com/xfey/HealthyVibe"

  depends_on macos: ">= :ventura"

  app "HealthyVibe.app"

  uninstall quit: "com.flintstudio.healthyvibe"

  uninstall_preflight do
    require "json"
    require "pathname"

    [
      [Pathname("#{Dir.home}/.claude/settings.json"), "claude"],
      [Pathname("#{Dir.home}/.codex/hooks.json"), "codex"],
    ].each do |path, agent|
      next unless path.exist?

      begin
        data = JSON.parse(path.read)
      rescue JSON::ParserError
        next
      end

      hooks = data["hooks"]
      groups = hooks&.[]("UserPromptSubmit")
      next unless groups.is_a?(Array)

      changed = false
      groups.map! do |group|
        next group unless group.is_a?(Hash)

        handlers = group["hooks"]
        next group unless handlers.is_a?(Array)

        remaining = handlers.reject do |handler|
          handler.is_a?(Hash) &&
            handler["command"].to_s.include?("HealthyVibe/hooks/agent-event.sh") &&
            handler["command"].to_s.include?(agent)
        end

        changed ||= remaining.length != handlers.length
        group["hooks"] = remaining

        if remaining.empty? && (group.keys - ["hooks", "matcher"]).empty?
          nil
        else
          group
        end
      end
      groups.compact!

      next unless changed

      if groups.empty?
        hooks.delete("UserPromptSubmit")
      else
        hooks["UserPromptSubmit"] = groups
      end
      data.delete("hooks") if hooks.empty?

      path.write(JSON.pretty_generate(data) + "\n")
    end
  end

  zap trash: [
    "~/Library/Application Support/HealthyVibe",
    "~/Library/Preferences/com.flintstudio.healthyvibe.plist",
  ]
end
