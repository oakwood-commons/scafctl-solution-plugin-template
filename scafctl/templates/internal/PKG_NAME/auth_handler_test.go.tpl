package <% .pkg_name %>

import (
	"context"
	"testing"

	sdkplugin "github.com/oakwood-commons/scafctl-plugin-sdk/plugin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// newTestPlugin creates a Plugin configured for testing.
// Always use this instead of &Plugin{} to avoid nil-pointer panics
// when ConfigureAuthHandler adds initialization logic.
func newTestPlugin(t *testing.T) *Plugin {
	t.Helper()
	p := &Plugin{}
	err := p.ConfigureAuthHandler(context.Background(), HandlerName, sdkplugin.ProviderConfig{
		BinaryName: "scafctl",
	})
	require.NoError(t, err)
	return p
}

func TestGetAuthHandlers(t *testing.T) {
	p := newTestPlugin(t)
	handlers, err := p.GetAuthHandlers(context.Background())
	require.NoError(t, err)
	require.Len(t, handlers, 1)
	assert.Equal(t, HandlerName, handlers[0].Name)
	assert.NotEmpty(t, handlers[0].DisplayName)
	assert.NotEmpty(t, handlers[0].Flows)
}

func TestConfigureAuthHandler(t *testing.T) {
	t.Run("known handler", func(t *testing.T) {
		p := &Plugin{}
		err := p.ConfigureAuthHandler(context.Background(), HandlerName, sdkplugin.ProviderConfig{
			BinaryName: "mycli",
		})
		require.NoError(t, err)
		assert.Equal(t, "mycli", p.cfg.BinaryName)
	})

	t.Run("unknown handler", func(t *testing.T) {
		p := &Plugin{}
		err := p.ConfigureAuthHandler(context.Background(), "unknown", sdkplugin.ProviderConfig{})
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "unknown handler")
	})
}

func TestLogin(t *testing.T) {
	p := newTestPlugin(t)

	t.Run("known handler", func(t *testing.T) {
		resp, err := p.Login(context.Background(), HandlerName, sdkplugin.LoginRequest{}, nil)
		require.NoError(t, err)
		assert.NotNil(t, resp.Claims)
		assert.NotEmpty(t, resp.Claims.Subject)
		assert.False(t, resp.ExpiresAt.IsZero())
	})

	t.Run("unknown handler", func(t *testing.T) {
		_, err := p.Login(context.Background(), "unknown", sdkplugin.LoginRequest{}, nil)
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "unknown handler")
	})
}

func TestLogout(t *testing.T) {
	p := newTestPlugin(t)

	t.Run("known handler", func(t *testing.T) {
		err := p.Logout(context.Background(), HandlerName)
		require.NoError(t, err)
	})

	t.Run("unknown handler", func(t *testing.T) {
		err := p.Logout(context.Background(), "unknown")
		assert.Error(t, err)
	})
}

func TestGetStatus(t *testing.T) {
	p := newTestPlugin(t)

	t.Run("known handler", func(t *testing.T) {
		status, err := p.GetStatus(context.Background(), HandlerName)
		require.NoError(t, err)
		assert.NotNil(t, status)
	})

	t.Run("unknown handler", func(t *testing.T) {
		_, err := p.GetStatus(context.Background(), "unknown")
		assert.Error(t, err)
	})
}

func TestGetToken(t *testing.T) {
	p := newTestPlugin(t)

	t.Run("not authenticated", func(t *testing.T) {
		_, err := p.GetToken(context.Background(), HandlerName, sdkplugin.TokenRequest{})
		assert.EqualError(t, err, "not authenticated")
	})

	t.Run("unknown handler", func(t *testing.T) {
		_, err := p.GetToken(context.Background(), "unknown", sdkplugin.TokenRequest{})
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "unknown handler")
	})
}

func TestListCachedTokens(t *testing.T) {
	p := newTestPlugin(t)
	tokens, err := p.ListCachedTokens(context.Background(), HandlerName)
	require.NoError(t, err)
	assert.Nil(t, tokens)
}

func TestPurgeExpiredTokens(t *testing.T) {
	p := newTestPlugin(t)
	count, err := p.PurgeExpiredTokens(context.Background(), HandlerName)
	require.NoError(t, err)
	assert.Equal(t, 0, count)
}

func TestDetectAvailableFlows(t *testing.T) {
	p := newTestPlugin(t)

	t.Run("known handler", func(t *testing.T) {
		flows, err := p.DetectAvailableFlows(context.Background(), HandlerName)
		require.NoError(t, err)
		assert.Nil(t, flows)
	})

	t.Run("unknown handler", func(t *testing.T) {
		_, err := p.DetectAvailableFlows(context.Background(), "unknown")
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "unknown handler")
	})
}

func BenchmarkGetToken(b *testing.B) {
	p := &Plugin{}
	if err := p.ConfigureAuthHandler(context.Background(), HandlerName, sdkplugin.ProviderConfig{
		BinaryName: "scafctl",
	}); err != nil {
		b.Fatal(err)
	}
	ctx := context.Background()
	req := sdkplugin.TokenRequest{}

	b.ReportAllocs()
	b.ResetTimer()

	for b.Loop() {
		_, _ = p.GetToken(ctx, HandlerName, req)
	}
}
