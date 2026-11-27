module <% .module %>

go 1.27.4

require (
	github.com/Masterminds/semver/v3 v3.5.0
	github.com/google/jsonschema-go v0.4.3
	github.com/oakwood-commons/scafctl-plugin-sdk v0.19.0
	github.com/stretchr/testify v1.12.1
<%- if eq .plugin_type "auth-handler" %>
	github.com/go-logr/logr v1.4.4
	github.com/oakwood-commons/oauth-helpers v0.3.0
<%- end %>
)
