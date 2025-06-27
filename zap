package main

import (
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"io"
	"os"
)

//var logger = NewCustomLogger(zap.InfoLevel, Console, "zap.log", CustomFields{"name", "TwelveBoyZ"})
//var sugar = logger.Sugar()

type outputFormat string

const (
	Json    outputFormat = "json"
	Console outputFormat = "console"
)

type CustomFields struct {
	Key   string
	Value string
}

// NewCustomLogger 创建一个自定义的zap.Logger实例
// loglevel: 日志等级
// format: 输出格式（Json或Console）
// logfile: 日志文件路径
func NewCustomLogger(loglevel zapcore.LevelEnabler, format outputFormat, logfile string, kv ...CustomFields) *zap.Logger {
	// 创建一个自定义编码器
	encoder := NewCustomEncoder(format)

	// 添加自定义字段
	encoder = AddFields(encoder, kv)

	// 多路输出
	zapLogFile, _ := os.OpenFile(logfile, os.O_CREATE|os.O_WRONLY|os.O_APPEND, os.ModePerm)
	w := io.MultiWriter(zapLogFile, os.Stdout)

	// 创建一个核心组件，将编码器和输出目标结合起来
	core := zapcore.NewCore(encoder, zapcore.AddSync(w), loglevel)

	// 创建一个Logger实例,并添加调用者信息和堆栈跟踪
	log := zap.New(core).WithOptions(zap.AddCaller(), zap.AddStacktrace(zap.ErrorLevel))

	return log
}

// AddFields 添加字段
func AddFields(encoder zapcore.Encoder, kv []CustomFields) zapcore.Encoder {
	if len(kv) > 0 {
		for _, field := range kv {
			// 添加自定义字段
			encoder.AddString(field.Key, field.Value)
		}
	}

	return encoder
}

// NewCustomEncoder 创建自定义编码器
func NewCustomEncoder(format outputFormat) zapcore.Encoder {
	encoderConfig := zapcore.EncoderConfig{
		MessageKey:     "message",                                               // 日志消息
		LevelKey:       "level",                                                 // 日志级别
		TimeKey:        "time",                                                  // 时间
		NameKey:        "Logger",                                                // 日志记录器名称
		CallerKey:      "caller",                                                // 调用者
		StacktraceKey:  "stacktrace",                                            // 堆栈跟踪
		FunctionKey:    zapcore.OmitKey,                                         // 函数名
		EncodeCaller:   zapcore.ShortCallerEncoder,                              // 调用者编码器
		EncodeDuration: zapcore.SecondsDurationEncoder,                          // 持续时间编码器
		EncodeTime:     zapcore.TimeEncoderOfLayout("2006-01-02T15:04:05.0000"), // 时间编码器
		EncodeLevel:    zapcore.CapitalLevelEncoder,                             // 日志级别大写
	}

	// 根据格式选择编码器
	switch format {
	case Json:
		return zapcore.NewJSONEncoder(encoderConfig)
	case Console:
		return zapcore.NewConsoleEncoder(encoderConfig)
	default:
		// 默认返回JSON编码器
		return zapcore.NewJSONEncoder(encoderConfig)
	}

}
