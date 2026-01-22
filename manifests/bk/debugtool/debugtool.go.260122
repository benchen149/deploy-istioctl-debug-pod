package debugtool

import (
	"bufio"
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"
)

func NewCommand() *cobra.Command {
	var outputDir, fqdn, cluster string
	var zipOutput bool

	cmd := &cobra.Command{
		Use:   "debugtool <namespace> <podname>",
		Short: "Query proxy-config outputs for a given pod",
		Args:  cobra.ExactArgs(2),
		RunE: func(cmd *cobra.Command, args []string) error {
			ns, pod := args[0], args[1]

			if strings.Contains(pod, ".") {
				parts := strings.SplitN(pod, ".", 2)
				pod = parts[0]
				ns = parts[1]
				fmt.Printf("⚠️ 偵測到 podname 帶有 namespace，解析為 namespace=%s, pod=%s\n", ns, pod)
			}
			fullPodName := fmt.Sprintf("%s.%s", pod, ns)

			var summaryFile *os.File
			if outputDir != "" {
				os.MkdirAll(outputDir, 0755)
				summaryFilePath := filepath.Join(outputDir, "debug-summary.txt")
				var err error
				summaryFile, err = os.Create(summaryFilePath)
				if err != nil {
					return fmt.Errorf("failed to create summary file: %v", err)
				}
				defer summaryFile.Close()
			}

			// proxy-status
			fmt.Println("🔍 Checking proxy status for selected pod...")
			proxyStatusCmd := exec.Command("istioctl", "proxy-status", "-n", ns)
			var proxyStatusOut bytes.Buffer
			proxyStatusCmd.Stdout = &proxyStatusOut
			proxyStatusCmd.Stderr = os.Stderr
			if err := proxyStatusCmd.Run(); err != nil {
				fmt.Printf("⚠️  Failed to get proxy status: %v\n", err)
			} else {
				scanner := bufio.NewScanner(&proxyStatusOut)
				for scanner.Scan() {
					line := scanner.Text()
					if strings.Contains(line, pod) {
						fmt.Println(line)
						if summaryFile != nil {
							summaryFile.WriteString(line + "\n")
						}
					}
				}
			}

			// proxy-config cluster (表格)
			fmt.Println("🔍 Fetching available clusters for selection...")
			clusterCmd := exec.Command("istioctl", "proxy-config", "cluster", "-n", ns, fullPodName)
			var clusterOut bytes.Buffer
			clusterCmd.Stdout = &clusterOut
			clusterCmd.Stderr = os.Stderr
			if err := clusterCmd.Run(); err != nil {
				return fmt.Errorf("failed to get clusters: %v", err)
			}
			fmt.Print(clusterOut.String()) // 同步印出表格內容

			if outputDir != "" {
				path := filepath.Join(outputDir, "cluster.txt")
				if err := os.WriteFile(path, clusterOut.Bytes(), 0644); err != nil {
					fmt.Printf("⚠️  Failed to write cluster.txt: %v\n", err)
				} else {
					fmt.Printf("💾 Output written to: %s\n", path)
					if summaryFile != nil {
						summaryFile.WriteString(fmt.Sprintf("✔ Output written to: %s\n", path))
					}
				}
			}

			// 解析 outbound clusters
			type serviceEntry struct {
				FQDN string
				Port string
			}
			var options []serviceEntry
			scanner := bufio.NewScanner(&clusterOut)
			for scanner.Scan() {
				line := scanner.Text()
				if strings.TrimSpace(line) == "" || strings.HasPrefix(line, "SERVICE FQDN") {
					continue
				}
				fields := strings.Fields(line)
				if len(fields) < 5 || !strings.Contains(line, "outbound") {
					continue
				}
				fqdn := fields[0]
				port := fields[1]
				if port != "-" {
					options = append(options, serviceEntry{FQDN: fqdn, Port: port})
				}
			}
			if len(options) == 0 {
				return fmt.Errorf("❌ no outbound clusters found")
			}

			fmt.Println("\n📋 Select one of the following outbound service targets:")
			for i, opt := range options {
				fmt.Printf("[%d] %s (port %s)\n", i+1, opt.FQDN, opt.Port)
			}
			fmt.Print("\n🔢 Enter selection number: ")
			var sel int
			fmt.Scanln(&sel)
			if sel < 1 || sel > len(options) {
				return fmt.Errorf("invalid selection")
			}
			selected := options[sel-1]
			fqdn = selected.FQDN
			cluster = fmt.Sprintf("outbound|%s||%s", selected.Port, selected.FQDN)

			fmt.Printf("✅ Selected FQDN: %s\n", fqdn)
			fmt.Printf("✅ Using cluster: %s\n\n", cluster)

			cmds := []struct {
				args     []string
				jsonOut  bool
				filename string
			}{
				{[]string{"proxy-config", "listeners", "-n", ns, pod}, false, "listeners.txt"},
				{[]string{"proxy-config", "listeners", fullPodName, "--port", "15001", "-o", "json"}, true, "listeners-15001.json"},
				{[]string{"proxy-config", "cluster", fullPodName, "--fqdn", fqdn, "-o", "json"}, true, fmt.Sprintf("cluster-%s.json", strings.ReplaceAll(fqdn, ".", "_"))},
				{[]string{"proxy-config", "endpoints", fullPodName, "--cluster", cluster}, false, "endpoints.txt"},
			}

			for _, c := range cmds {
				cmdStr := fmt.Sprintf(">>> istioctl %s\n", strings.Join(c.args, " "))
				fmt.Print(cmdStr)
				if summaryFile != nil {
					summaryFile.WriteString(cmdStr)
				}

				sub := exec.Command("istioctl", c.args...)
				var buf bytes.Buffer
				sub.Stdout = &buf
				sub.Stderr = os.Stderr
				if err := sub.Run(); err != nil {
					fmt.Printf("⚠️  Command failed: %v\n", err)
					continue
				}

				// CLI 同步印出
				fmt.Print(buf.String())

				// 寫入檔案
				if outputDir != "" && c.filename != "" {
					path := filepath.Join(outputDir, c.filename)
					if err := os.WriteFile(path, buf.Bytes(), 0644); err != nil {
						fmt.Printf("⚠️  Failed to write file: %v\n", err)
					} else {
						fmt.Printf("💾 Output written to: %s\n", path)
						if summaryFile != nil {
							summaryFile.WriteString(fmt.Sprintf("✔ Output written to: %s\n", path))
						}
					}

					// 額外複製 cluster.json
					if strings.HasPrefix(c.filename, "cluster-") {
						altPath := filepath.Join(outputDir, "cluster.json")
						if err := os.WriteFile(altPath, buf.Bytes(), 0644); err != nil {
							fmt.Printf("⚠️  Failed to write cluster.json: %v\n", err)
						} else {
							fmt.Printf("💾 Output written to: %s\n", altPath)
							if summaryFile != nil {
								summaryFile.WriteString(fmt.Sprintf("✔ Output written to: %s\n", altPath))
							}
						}
					}
				}
			}
			return nil
		},
	}

	cmd.Flags().StringVarP(&outputDir, "output-dir", "o", "", "Directory to save output and summary")
	cmd.Flags().StringVar(&fqdn, "fqdn", "", "Optional FQDN of target service")
	cmd.Flags().StringVar(&cluster, "cluster", "", "Optional cluster name")
	cmd.Flags().BoolVar(&zipOutput, "zip", false, "Zip the outputs (not yet implemented)")
	return cmd
}