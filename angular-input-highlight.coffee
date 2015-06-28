
angular.module 'input-highlight', []
  .directive 'highlight', ['$parse', ($parse) ->
    restrict   : 'A'
    link       : (scope, el, attrs) ->
      input = el[0]
      return unless input.tagName is 'TEXTAREA' 

      spread    = 2
      mirror    = angular.element('<div style="position:relative"></div>')[0]
      container = angular.element('<div style="position:absolute;width:0px;height:0px;overflow:hidden;"></div>')[0]
      textProps = ['font-size', 'font-family', 'font-style', 'font-weight', 'font-variant', 'font-stretch', 
        'line-height', 'vertical-align', 'word-spacing', 'text-align', 'letter-spacing', 'text-rendering'
        'padding', 'border']

      document.body.appendChild container
      container.appendChild mirror

      el.css 
        'background-position' : '0 0'
        'background-repeat'   : 'no-repeat'

      style = window.getComputedStyle input
      mirror.style['white-space'] = 'pre-wrap'
      console.log 'font-family', style['font-family']
      for prop in textProps
        mirror.style[prop] = style[prop]

      el.css 'resize', 'vertical' if style['resize'] is 'both'
      el.css 'resize', 'none'     if style['resize'] is 'horizontal'

      formatting = scope[attrs.highlight] or {}
      
      onChange = angular.noop
      if attrs.highlightOnchange
        onChange = do ->
          fn = $parse attrs.highlightOnchange
          (markers) -> fn scope, $markers: markers

      canvas = document.createElement('canvas')
      ctx    = canvas.getContext('2d')

      render = (text) ->
        markers      = []
        originalText = text
        
        mirror.innerHTML = text
        mirror.style.width = style.width;
        canvas.width  = mirror.clientWidth
        canvas.height = mirror.clientHeight

        for color, re of formatting
          mirror.innerHTML = text.replace re, (s) -> 
            "<span style=\"position:relative\" data-marker=\"#{color}\">#{s}</span>"

          for m in mirror.querySelectorAll 'span[data-marker]'
            marker = 
              text   : m.innerHTML
              color  : m.getAttribute 'data-marker'
              x      : m.offsetLeft - spread
              y      : m.offsetTop
              width  : m.offsetWidth  + 2 * spread - 1
              height : m.offsetHeight + 1

            ctx.fillStyle = color
            ctx.fillRect marker.x, marker.y, marker.width, marker.height

            markers.push marker

        el.css 'background-image', "url(#{canvas.toDataURL()})"
        onChange markers

      if attrs.ngModel
        scope.$watch attrs.ngModel, render
      else
        render input.value
        anguar.element input
          .on 'change', -> render this.value

      scope.$watch attrs.highlight, (_formatting) ->
        formatting = _formatting or {}
        render input.value
      , true

      scope.$on '$destroy', ->
        container.parentNode.removeChild container

      el.on 'scroll', ->
        el.css 'background-position', "0 -#{input.scrollTop}px"
  ]
  