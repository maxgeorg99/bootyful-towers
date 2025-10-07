---@class (exact) vibes.Deck
---@field new fun(): vibes.Deck
---@field init fun(self: vibes.Deck)
---@field draw_pile vibes.Card[]
---@field hand vibes.Card[]
---@field discard_pile vibes.Card[]
---@field exhausted_pile vibes.Card[]
--
-- Public Methods
---@field reset fun(self: vibes.Deck): nil
---@field discard_card fun(self: vibes.Deck, card: vibes.Card): nil
---@field exhaust_card fun(self: vibes.Deck, card: vibes.Card, target?:Element): nil
---@field get_all_cards fun(self: vibes.Deck): vibes.Card[]
---@field draw_cards fun(self: vibes.Deck, count: number): nil
---@field draw_cards_with_guaranteed_towers fun(self: vibes.Deck, total_cards: number, guaranteed_towers: number): nil
---@field count_towers_in_hand fun(self: vibes.Deck): number
--
-- Static Methods
---@field create_default_deck fun(): vibes.Deck
---@field create_character_deck fun(character_kind: CharacterKind): vibes.Deck
local Deck = class "vibes.Deck"

--- @return vibes.Deck
function Deck:init()
  self.draw_pile = {}
  self.hand = {}
  self.discard_pile = {}
  self.exhausted_pile = {}
end

--- Preserves references to the source array, very important to
--- make sure we don't copy & goof up random state throuhgout the game.
---@param opts {src: vibes.Card[], dst: vibes.Card[]}
local empty_src_to_dst = function(opts)
  local src = opts.src
  local dst = opts.dst

  while #src > 0 do
    table.insert(dst, table.remove(src, 1))
  end
end

function Deck:reset()
  empty_src_to_dst { src = self.hand, dst = self.draw_pile }
  empty_src_to_dst { src = self.discard_pile, dst = self.draw_pile }
  empty_src_to_dst { src = self.exhausted_pile, dst = self.draw_pile }

  self:_shuffle()
end

---@return vibes.Card[]
function Deck:get_all_cards()
  local all_cards = {}
  local piles = {
    self.draw_pile,
    self.discard_pile,
    self.exhausted_pile,
    self.hand,
  }
  for _, pile in ipairs(piles) do
    for _, card in ipairs(pile) do
      table.insert(all_cards, card)
    end
  end
  return all_cards
end

---@return vibes.EnhancementCard[]
function Deck:get_all_enhancements()
  local enhancements = {}
  local piles = {
    self.draw_pile,
    self.discard_pile,
    self.exhausted_pile,
    self.hand,
  }
  for _, pile in ipairs(piles) do
    for _, card in ipairs(pile) do
      if card.kind == CardKind.ENHANCEMENT then
        table.insert(enhancements, card)
      end
    end
  end
  return enhancements
end

---@param card vibes.Card
function Deck:trash_card(card)
  local enhancements = {}
  local piles = {
    self.draw_pile,
    self.discard_pile,
    self.exhausted_pile,
    self.hand,
  }
  for _, pile in ipairs(piles) do
    for idx, c in ipairs(pile) do
      if c.id == card.id then
        logger.debug("trashing card", c.id, c.name, c.rarity)
        table.remove(pile, idx)
        return
      end
    end
  end
  return enhancements
end

--- Move a card to the discard pile. DOES NOT COUNT AS A DISCARD ACTION!
---@param card vibes.Card
---@return vibes.Card? discarded_card
function Deck:_move_card_to_discard_pile(card)
  for idx, c in ipairs(self.hand) do
    if c.id == card.id then
      table.remove(self.hand, idx)
    end
  end

  table.insert(self.discard_pile, card)
  return card
end

---@param card_elements components.GameCardElement[]

---@param card vibes.Card
function Deck:discard_card(card)
  logger.debug(
    "Deck:discard_card() - Discarding card: %s (id=%s)",
    card.name or "unknown",
    card.id or "no-id"
  )
  if self:_move_card_to_discard_pile(card) then
    logger.debug(
      "Deck:discard_card() - Successfully discarded card. Discard pile now has %d cards",
      #self.discard_pile
    )
    EventBus:emit_card_discard { card = card }
  else
    logger.warn(
      "Deck:discard_card() - Failed to discard card: %s (id=%s)",
      card.name or "unknown",
      card.id or "no-id"
    )
  end
end

---@param card vibes.Card
---@return vibes.Card? exhausted_card
function Deck:_move_card_to_exhausted_pile(card)
  for idx, c in ipairs(self.hand) do
    if c.id == card.id then
      table.remove(self.hand, idx)
    end
  end

  table.insert(self.exhausted_pile, card)
  return card
end

---@param card vibes.Card
---@param target? Element
function Deck:exhaust_card(card, target)
  if self:_move_card_to_exhausted_pile(card) then
    EventBus:emit_card_exhaust { card = card, target = target }
  end
end

---@param count number
function Deck:draw_cards(count)
  for _ = 1, count do
    table.insert(self.hand, table.shift(self.draw_pile))
  end
end

function Deck:draw_card()
  if #self.draw_pile == 0 and #self.discard_pile == 0 then
    return
  end

  if #self.draw_pile == 0 then
    self:_shuffle_discards_into_draw_pile()
    self:_shuffle()
  end

  local card = table.shift(self.draw_pile)
  table.insert(self.hand, card)

  EventBus:emit_card_draw { card = card }
end
function Deck:draw_hand()
  local cards_in_hand = #State.deck.hand
  local cards_to_draw = math.max(State.player.hand_size - cards_in_hand, 0)

  local delay = 75

  for i = 1, cards_to_draw do
    Timer.oneshot(i * delay, function() self:draw_card() end)
  end
end
--- Draw cards ensuring at least a certain number of tower cards are drawn first
--- This is used when starting a new level to guarantee tower cards in hand
---@param total_cards number: Total number of cards to draw
---@param guaranteed_towers number: Number of tower cards to guarantee (max 2)
function Deck:draw_cards_with_guaranteed_towers(total_cards, guaranteed_towers)
  guaranteed_towers = math.min(guaranteed_towers or 2, 2) -- Cap at 2 towers max

  local towers_drawn = 0
  local cards_drawn = 0
  local tower_indices = {}

  -- First pass: find tower cards in draw pile
  for i, card in ipairs(self.draw_pile) do
    if card.kind == CardKind.TOWER then
      table.insert(tower_indices, i)
    end
  end

  -- Draw guaranteed tower cards first (from the back to avoid index shifting)
  for i = #tower_indices, 1, -1 do
    if towers_drawn >= guaranteed_towers then
      break
    end

    local tower_index = tower_indices[i]
    local tower_card = table.remove(self.draw_pile, tower_index)
    table.insert(self.hand, tower_card)
    towers_drawn = towers_drawn + 1
    cards_drawn = cards_drawn + 1
  end

  -- Draw remaining cards normally
  local remaining_cards = total_cards - cards_drawn
  for _ = 1, remaining_cards do
    if #self.draw_pile > 0 then
      table.insert(self.hand, table.shift(self.draw_pile))
      cards_drawn = cards_drawn + 1
    else
      break -- No more cards to draw
    end
  end

  logger.info(
    "Drew %d cards (%d towers guaranteed, %d total towers in hand)",
    cards_drawn,
    towers_drawn,
    self:count_towers_in_hand()
  )
end

--- Count the number of tower cards currently in hand
---@return number
function Deck:count_towers_in_hand()
  local count = 0
  for _, card in ipairs(self.hand) do
    if card.kind == CardKind.TOWER then
      count = count + 1
    end
  end
  return count
end

---@param card vibes.Card
function Deck:handle_card_after_play(card)
  local after_play_kind = card.after_play_kind
  if after_play_kind == CardAfterPlay.DISCARD then
    return self:discard_card(card)
  elseif after_play_kind == CardAfterPlay.EXHAUST then
    return self:exhaust_card(card)
  elseif after_play_kind == CardAfterPlay.NEVER then
    -- Card stays in hand, do nothing
    return
  else
    error("Invalid after play kind: " .. after_play_kind)
  end
end

--- @param card vibes.Card
function Deck:add_card(card)
  --- @TODO add_card may have to consider adding to current hand.
  table.insert(self.draw_pile, card)
end

---@param pile vibes.Card[]
---@param card vibes.Card
---@return number?
function Deck:_find_card(pile, card)
  for i, c in ipairs(pile) do
    if c:eql(card) then
      return i
    end
  end
end

function Deck:_shuffle_discards_into_draw_pile()
  while #State.deck.discard_pile > 0 do
    local card = table.shift(State.deck.discard_pile)
    table.insert(State.deck.draw_pile, card)
  end

  self:_shuffle()
end

--- Fisher-Yates shuffle algorithm
function Deck:_shuffle()
  local cards = self.draw_pile
  local n = #cards

  if n <= 1 then
    return
  end

  for i = n, 2, -1 do
    local j = math.random(i)
    cards[i], cards[j] = cards[j], cards[i]
  end
end

return Deck
