import { NodeSDK } from '@opentelemetry/sdk-node'
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-proto'
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-node'

const traceExporter = new OTLPTraceExporter({
	url: `${process.env.AXIOM_URL}/v1/traces`,
	headers: {
		Authorization: `Bearer ${process.env.AXIOM_AUTH}`,
		'X-Axiom-Dataset': process.env.AXIOM_DATASET || ''
	}
})

const sdk = new NodeSDK({
	serviceName: process.env.SITE_NAME || '',
	spanProcessor: new BatchSpanProcessor(traceExporter)
})

sdk.start()
