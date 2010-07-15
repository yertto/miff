module Details
  def self.fix(details)
    case details
      when "D/P/S Anita Killi WS Norwegian Film Institute L Norwegian w/English subtitles TD 35mm or Digi Beta/2009"
           "D/P/S Anita Killi WS Norwegian Film Institute L Norwegian w/English subtitles TD 35mm/2009"
      when "'Every cook in this movie has a recipe how to survive during an extreme situation. How to keep your own personality.'\342\200\223 filmmaker Peter Kerekes."
           "D Péter Kerekes TD 2009"
      when "\342\200\234Evokes the complex masterpieces of Margarethe von Trotta's early work\342\200\246 Unflinching in its gaze and direct in its emotional connection.\342\200\235 \342\200\223 Toronto International Film Festival"
           "D/S Susanne Schneider TD 2009"
      when "Director Yael Hersonski is a guest of the Festival."
           "D Yael Hersonski TD 2010"
      when "Join seven astronauts aboard the Space Shuttle Atlantis as they embark on a mission to repair the Hubble Space Telescope. See the solar system in eye-popping 3D."
           "D Toni Myers TD 2010"
      when "D/S Spike Jonze P Vincent Landay WS CAA TD HD CAM/2010"
           "D/S Spike Jonze P Vincent Landay WS CAA TD HDCAM/2010"
      when "D/S Ashlee Page P Sonya Humphrey WS Sacred Cow Films TD digibeta2010"
           "D/S Ashlee Page P Sonya Humphrey WS Sacred Cow Films TD digibeta/2010"
      when "\342\200\234Joe Dante knows the truth \342\200\223 that the cinema of his childhood was haunted by the nation's guilt for Hiroshima.\342\200\235 \342\200\223 Bill Krohn"
           "D Joe Dante TD 1993"
      when "A biting social satire that lampoons both government and media in one fell swoop, Peepli Live puts a comedic spin on one of the darkest issues facing India today. First-time filmmaker Anusha Rizvi shines a spotlight on an uncomfortable subject, and turns it into outrageous farce."
           "D Anusha Rizvi TD 2010"
      when "Films courtesy of the National Film and Sound Archive of Australia."
           "D  TD 1896"
      when "D Mat Whitecross P Damian Jones S Paul Viragh Dist Transmission Films TD 35mm/2010\r\r\r\r\302\240\r\r\r\rSex&Drugs&Rock&Roll is screening as MIFF's Closing Night film. Book here"
           "D Mat Whitecross P Damian Jones S Paul Viragh Dist Transmission Films TD 35mm/2010"
      when "Mashing up religion and politics, Taqwacore brings a new brand of punk to the mosque pit."
           "D Omar Majeed TD 2009"
      when "Documentary filmmaker Romuald Karmakar gains unprecedented access to the working space and methods of Villalobos, including a comprehensive look at his custom-made sound system and massive synth collection. Appealing to house music fans and newcomers to the genre, Villalobos is a sensual delight for the eyes and ears."
           "D Romuald Karmakar TD 2009"
      when "\342\200\234People know these things happen, but they tend to turn a blind eye. And if you don't talk about it, you think you're the only one.\342\200\235 \342\200\223 filmmaker and model Sara Ziff"
           "D Sara Ziff TD 2009"
    else
      details
    end
  end
end
