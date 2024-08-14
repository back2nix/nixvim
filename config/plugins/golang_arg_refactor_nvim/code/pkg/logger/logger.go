package logger

import (
	"fmt"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

var Log, _ = NewLogger(true)

// Logger is a wrapper around zap.Logger with enable/disable functionality
type Logger struct {
	enabled bool
	logger  *zap.Logger
	sugar   *zap.SugaredLogger // Добавлено поле sugar
}

// NewLogger creates a new Logger instance
func NewLogger(enabled bool) (*Logger, error) {
	config := zap.NewProductionConfig()
	config.EncoderConfig.EncodeTime = zapcore.ISO8601TimeEncoder
	zapLogger, err := config.Build()
	if err != nil {
		return nil, err
	}

	sugar := zapLogger.Sugar()

	return &Logger{
		enabled: enabled,
		logger:  zapLogger,
		sugar:   sugar,
	}, nil
}

// Debug logs a debug message if logging is enabled
func (l *Logger) Debug(msg string, fields ...zap.Field) {
	if l.enabled {
		l.logger.Debug(msg, fields...)
	}
}

// DebugPrintf logs a debug message with printf-like formatting if logging is enabled
func (l *Logger) DebugPrintf(format string, args ...interface{}) {
	if l.enabled {
		fmt.Printf(format+"\n", args...)
	}
}

// Info logs an info message if logging is enabled
func (l *Logger) Info(msg string, fields ...zap.Field) {
	if l.enabled {
		l.logger.Info(msg, fields...)
	}
}

// Warn logs a warning message if logging is enabled
func (l *Logger) Warn(msg string, fields ...zap.Field) {
	if l.enabled {
		l.logger.Warn(msg, fields...)
	}
}

// Error logs an error message if logging is enabled
func (l *Logger) Error(msg string, fields ...zap.Field) {
	if l.enabled {
		l.logger.Error(msg, fields...)
	}
}

// SetEnabled enables or disables logging
func (l *Logger) SetEnabled(enabled bool) {
	l.enabled = enabled
}

// Sync flushes any buffered log entries
func (l *Logger) Sync() error {
	return l.logger.Sync()
}
