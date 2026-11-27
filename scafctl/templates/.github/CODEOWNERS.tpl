<%- if .codeowners -%>
# Default owners for everything
* <% .codeowners %>
<%- else -%>
# Set default owners (for example: * @myorg/maintainers or * @username)
<%- end %>
