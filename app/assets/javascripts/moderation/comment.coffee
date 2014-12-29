# Toggle button
$(document).on "click", "button[name=mod-comments]", ->
  btn = $(this)
  id = btn[0].dataset.id
  state = btn[0].dataset.state
  commentBox = $("#mod-comments-section-#{id}")

  switch state
    when 'hidden'
      commentBox.slideDown()
      btn[0].dataset.state = 'shown'
    when 'shown'
      commentBox.slideUp()
      btn[0].dataset.state = 'hidden'


$(document).on "keyup", "input[name=mod-comment-new]", (evt) ->
  input = $(this)
  id = input[0].dataset.id
  ctr = $("span#mod-comment-charcount-#{id}")
  cbox = $("div[name=mod-comment-new-group][data-id=#{id}]")

  if evt.which == 13  # return key
    evt.preventDefault()
    return cbox.addClass "has-error" if input.val().length > 160 || input.val().trim().length == 0
    input.attr 'disabled', 'disabled'

    $.ajax
      url: '/ajax/mod/create_comment'
      type: 'POST'
      data:
        id: id
        comment: input.val()
      dataType: 'json' # jQuery can't guess the datatype correctly here...
      success: (data, status, jqxhr) ->
        console.log data
        if data.success
          $("#mod-comments-#{id}").html data.render
          input.val ''
          ctr.html 160
          $("span#mod-comment-count-#{id}").html data.count
        showNotification data.message, data.success
      error: (jqxhr, status, error) ->
        console.log jqxhr, status, error
        showNotification "An error occurred, a developer should check the console for details", false
      complete: (jqxhr, status) ->
        input.removeAttr 'disabled'


# character count
$(document).on "input", "input[name=mod-comment-new]", (evt) ->
  input = $(this)
  id = input[0].dataset.id
  ctr = $("span#mod-comment-charcount-#{id}")

  cbox = $("div[name=mod-comment-new-group][data-id=#{id}]")
  cbox.removeClass "has-error" if cbox.hasClass "has-error"

  ctr.html 160 - input.val().length
  if Number(ctr.html()) < 0
    ctr.removeClass 'text-muted'
    ctr.addClass 'text-danger'
  else
    ctr.removeClass 'text-danger'
    ctr.addClass 'text-muted'


# destroy
$(document).on "click", "a[data-action=mod-comment-destroy]", (ev) ->
  ev.preventDefault()
  if confirm 'Are you sure?'
    btn = $(this)
    cid = btn[0].dataset.id
    $.ajax
      url: '/ajax/mod/destroy_comment'
      type: 'POST'
      data:
        comment: cid
      success: (data, status, jqxhr) ->
        if data.success
          $("li[data-comment-id=#{cid}]").slideUp()
        showNotification data.message, data.success
      error: (jqxhr, status, error) ->
        console.log jqxhr, status, error
        showNotification "An error occurred, a developer should check the console for details", false
      complete: (jqxhr, status) ->