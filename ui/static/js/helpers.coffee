window.cx = React.addons.classSet
window.slugify  = (s) -> s.toLowerCase().replace /\W+/g, '-'

# Mixins
# --------------------------------------------------------------------------

window.StoredStateMixin =

    setStoredState: (cb) ->
        @setState @getStoredState(), cb

