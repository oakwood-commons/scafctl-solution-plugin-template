module <% .module %>

go 1.26

require (
	github.com/Masterminds/semver/v3 v3.3.1
	github.com/google/jsonschema-go v0.4.2
	github.com/oakwood-commons/scafctl-plugin-sdk v0.5.0
	github.com/stretchr/testify v1.10.0
<%- if eq .plugin_type "auth-handler" %>
	github.com/go-logr/logr v1.4.3
	github.com/oakwood-commons/oauth-helpers v0.2.0
<%- end %>
)
