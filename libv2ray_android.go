package libv2ray

// ProcessFinder is an interface for Android process finding functionality.
// Apps using AndroidLibXrayLite should implement FindProcessByConnection()
// and pass the implementation to RegisterProcessFinder() before starting the core.
//
// NOTE: this build pins Xray-core v1.260123.0-patch.1 (permissive TLS line:
// allowInsecure + plain VLESS/Trojan supported). That core predates
// common/net.RegisterAndroidProcessFinder (26.9.x+), so the finder cannot be
// forwarded to the core. The API is kept for app compatibility; per-app
// (UID-based) routing attribution is a no-op with this core build.
type ProcessFinder interface {
	// FindProcessByConnection finds the UID of the process that owns the given connection.
	//
	// network: Protocol type: "tcp" or "udp"
	// srcIP: Source IP address
	// srcPort: Source port
	// destIP: Destination IP address
	// destPort: Destination port
	// Returns the UID of the owning process, or -1 if not found.
	FindProcessByConnection(network, srcIP string, srcPort int, destIP string, destPort int) int
}

// RegisterProcessFinder registers an Android process finder with Xray-core,
// enabling per-app routing based on UID. Must be called before starting the
// core for process-based routing rules to work.
// Pass nil to unregister a previously registered finder.
//
// No-op on this core build (see ProcessFinder note above).
func (x *CoreController) RegisterProcessFinder(finder ProcessFinder) {
}
