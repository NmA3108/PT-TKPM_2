window.dashboardCharts = {
    renderKpiChart: (canvasId, labels, gmv, orders) => {
        const canvas = document.getElementById(canvasId);
        if (!canvas || !window.Chart) {
            return;
        }

        if (canvas._chartInstance) {
            canvas._chartInstance.destroy();
        }

        canvas._chartInstance = new Chart(canvas, {
            type: "bar",
            data: {
                labels,
                datasets: [
                    {
                        type: "line",
                        label: "GMV",
                        data: gmv,
                        borderColor: "#0d6efd",
                        backgroundColor: "rgba(13,110,253,.12)",
                        tension: .35,
                        yAxisID: "y"
                    },
                    {
                        label: "Đơn hàng",
                        data: orders,
                        backgroundColor: "rgba(25,135,84,.55)",
                        yAxisID: "y1"
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                interaction: { mode: "index", intersect: false },
                scales: {
                    y: { beginAtZero: true, position: "left" },
                    y1: { beginAtZero: true, position: "right", grid: { drawOnChartArea: false } }
                }
            }
        });
    },
    downloadBytes: (fileName, contentType, base64) => {
        const link = document.createElement("a");
        link.href = `data:${contentType};base64,${base64}`;
        link.download = fileName;
        link.click();
    }
};
