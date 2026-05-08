// Package <% .pkg_name %> implements the <% .handler_name %> auth handler plugin.
package <% .pkg_name %>

import (
	"context"
	"fmt"
	"time"

	"github.com/go-logr/logr"
	"github.com/oakwood-commons/scafctl-plugin-sdk/auth"
	sdkplugin "github.com/oakwood-commons/scafctl-plugin-sdk/plugin"
)

const (
	// HandlerName is the unique identifier for this auth handler.
	HandlerName = "<% .handler_name %>"

	// Version is the auth handler version.
	Version = "0.1.0"
)

// Plugin implements the scafctl AuthHandlerPlugin interface.
type Plugin struct {
	cfg sdkplugin.ProviderConfig

	// TODO: add handler state, initialized in ConfigureAuthHandler:
	//   httpClient HTTPClient    // for calling OAuth/API endpoints
	//   clock      clock.Clock   // for testable time operations (polling flows)
	//   config     *Config       // handler-specific configuration
}

// GetAuthHandlers returns the list of auth handlers exposed by this plugin.
//
//nolint:revive // ctx required by interface
func (p *Plugin) GetAuthHandlers(_ context.Context) ([]sdkplugin.AuthHandlerInfo, error) {
	return []sdkplugin.AuthHandlerInfo{
		{
			Name:        HandlerName,
			DisplayName: "<% .display_name %>",
			Flows:       []auth.Flow{auth.FlowDeviceCode},
			Capabilities: []auth.Capability{
				auth.CapScopesOnLogin,
			},
		},
	}, nil
}

// ConfigureAuthHandler stores host-side configuration and initializes
// the plugin. This runs once at plugin load, before Login/GetToken.
//
//nolint:revive // ctx required by interface
func (p *Plugin) ConfigureAuthHandler(_ context.Context, handlerName string, cfg sdkplugin.ProviderConfig) error {
	if handlerName != HandlerName {
		return fmt.Errorf("unknown handler: %s", handlerName)
	}
	p.cfg = cfg

	// TODO: initialize handler state here:
	//   p.config = DefaultConfig()
	//   p.httpClient = NewDefaultHTTPClient()

	return nil
}

// Login performs the authentication flow.
//
//nolint:revive // req and cb params required by interface
func (p *Plugin) Login(ctx context.Context, handlerName string, _ sdkplugin.LoginRequest, _ func(sdkplugin.DeviceCodePrompt)) (*sdkplugin.LoginResponse, error) {
	if handlerName != HandlerName {
		return nil, fmt.Errorf("unknown handler: %s", handlerName)
	}

	lgr := logr.FromContextOrDiscard(ctx)
	lgr.V(1).Info("login flow started")

	// Access the host secret store for persisting tokens across sessions:
	//   hostClient := sdkplugin.HostClientFromContext(ctx)
	//   if hostClient != nil {
	//       _ = hostClient.SetSecret(ctx, "my-handler.access_token", tokenValue)
	//   }

	// TODO: implement your authentication flow here
	return &sdkplugin.LoginResponse{
		Claims: &auth.Claims{
			Subject: "user@example.com",
			Email:   "user@example.com",
			Name:    "Example User",
		},
		ExpiresAt: time.Now().Add(24 * time.Hour),
	}, nil
}

// Logout revokes the current session.
func (p *Plugin) Logout(ctx context.Context, handlerName string) error {
	if handlerName != HandlerName {
		return fmt.Errorf("unknown handler: %s", handlerName)
	}

	// TODO: clear persisted credentials via the host secret store:
	//   hostClient := sdkplugin.HostClientFromContext(ctx)
	//   if hostClient != nil {
	//       _ = hostClient.DeleteSecret(ctx, "my-handler.access_token")
	//       _ = hostClient.DeleteSecret(ctx, "my-handler.refresh_token")
	//   }

	return nil
}

// GetStatus returns the current authentication status.
//
//nolint:revive // all params required by interface
func (p *Plugin) GetStatus(_ context.Context, handlerName string) (*auth.Status, error) {
	if handlerName != HandlerName {
		return nil, fmt.Errorf("unknown handler: %s", handlerName)
	}
	return &auth.Status{Authenticated: false}, nil
}

// GetToken returns a valid access token, refreshing if necessary.
//
//nolint:revive // all params required by interface
func (p *Plugin) GetToken(_ context.Context, handlerName string, _ sdkplugin.TokenRequest) (*sdkplugin.TokenResponse, error) {
	if handlerName != HandlerName {
		return nil, fmt.Errorf("unknown handler: %s", handlerName)
	}

	// TODO: implement token retrieval/refresh logic here
	return nil, fmt.Errorf("not authenticated")
}

// ListCachedTokens returns information about cached tokens.
//
//nolint:revive // all params required by interface
func (p *Plugin) ListCachedTokens(_ context.Context, handlerName string) ([]*auth.CachedTokenInfo, error) {
	if handlerName != HandlerName {
		return nil, fmt.Errorf("unknown handler: %s", handlerName)
	}
	return nil, nil
}

// PurgeExpiredTokens removes expired tokens from the cache.
//
//nolint:revive // all params required by interface
func (p *Plugin) PurgeExpiredTokens(_ context.Context, handlerName string) (int, error) {
	if handlerName != HandlerName {
		return 0, fmt.Errorf("unknown handler: %s", handlerName)
	}
	return 0, nil
}

// StopAuthHandler performs cleanup for the named handler.
//
//nolint:revive // all params required by interface
func (p *Plugin) StopAuthHandler(_ context.Context, _ string) error {
	return nil
}

// DetectAvailableFlows reports which auth flows have pre-existing credentials.
//
//nolint:revive // all params required by interface
func (p *Plugin) DetectAvailableFlows(_ context.Context, handlerName string) ([]sdkplugin.FlowAvailability, error) {
	if handlerName != HandlerName {
		return nil, fmt.Errorf("unknown handler: %s", handlerName)
	}

	// TODO: detect available flows based on environment credentials
	return nil, nil
}
