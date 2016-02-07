{SelectListView, $, $$} = require 'atom-space-pen-views'
{match} = require 'fuzzaldrin'
fuzzaldrinPlus = require 'fuzzaldrin-plus'

module.exports =
class MacroNameSelectListView extends SelectListView
  panel: null
  callback: null

  initialize: (@listOfItems) ->
    super
    @setItems(@listOfItems)
    self = this
    #@element.onkeydown = (e) ->
      #if e.keyIdentifier == 'Enter'
      #  value = self.filterEditorView.getText()
      #  param = {name: value}
      #  self.confirmed?(param)
      #if e.keyIdentifier == 'Escape'
      #  self.cancel()

  show: ->
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()

    @storeFocusedElement()

    if @previouslyFocusedElement[0] and @previouslyFocusedElement[0] isnt document.body
      @eventElement = @previouslyFocusedElement[0]
    else
      @eventElement = atom.views.getView(atom.workspace)

    @setItems(@items)

    @focusFilterEditor()

  hide: ->
    @panel?.hide()

  addItem: (item) ->
    @items ?= []
    @items.push
      name: item

    @setItems @items

  clearText: ->
    @filterEditorView.setText('')

  setCallback: (callback) ->
    @callback = callback

  focus: ->
    @focusFilterEditor()

  getElement: ->
    @element

  cancel: ->
    @hide()

  confirmed: ({name}) ->
    @clearText()
    @callback?(name)

  getFilterKey: ->
    'name'

  #viewForItem: (item) ->
  #  console.log('viewForItem', item)
  #  $$ -> @li(item)

  #viewForItem: ({name, displayName, eventDescription}) ->
  viewForItem: ({name}) ->
    # Style matched characters in search results
    filterQuery = @getFilterQuery()
    if @alternateScoring
      matches = fuzzaldrinPlus.match(name, filterQuery)
    else
      matches = match(name, filterQuery)

    $$ ->
      highlighter = (command, matches, offsetIndex) =>
        lastIndex = 0
        matchedChars = [] # Build up a set of matched chars to be more semantic

        for matchIndex in matches
          matchIndex -= offsetIndex
          continue if matchIndex < 0 # If marking up the basename, omit command matches
          unmatched = command.substring(lastIndex, matchIndex)
          if unmatched
            @span matchedChars.join(''), class: 'character-match' if matchedChars.length
            matchedChars = []
            @text unmatched
          matchedChars.push(command[matchIndex])
          lastIndex = matchIndex + 1

        @span matchedChars.join(''), class: 'character-match' if matchedChars.length

        # Remaining characters are plain text
        @text command.substring(lastIndex)

      @li class: 'event', 'data-event-name': name, =>
        #@div class: 'pull-right', =>
        #  for binding in keyBindings when binding.command is name
        #    @kbd _.humanizeKeystroke(binding.keystrokes), class: 'key-binding'
        @span title: name, -> highlighter(name, matches, 0)

  populateList: ->
    if @alternateScoring
      @populateAlternateList()
    else
      super

  # This is modified copy/paste from SelectListView#populateList, require jQuery!
  # Should be temporary
  populateAlternateList: ->
    return unless @items?

    filterQuery = @getFilterQuery()
    if filterQuery.length
      filteredItems = fuzzaldrinPlus.filter(@items, filterQuery, key: 'name')
    else
      filteredItems = @items

    @list.empty()
    if filteredItems.length
      @setError(null)

      for i in [0...Math.min(filteredItems.length, @maxItems)]
        item = filteredItems[i]
        itemView = $(@viewForItem(item))
        itemView.data('select-list-item', item)
        @list.append(itemView)

      @selectItemView(@list.find('li:first'))
    else
      @setError(@getEmptyMessage(@items.length, filteredItems.length))