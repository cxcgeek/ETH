// Copyright 2017 The go-ethereum Authors
// This file is part of the go-ethereum library.
//
// The go-ethereum library is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// The go-ethereum library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with the go-ethereum library. If not, see <http://www.gnu.org/licenses/>.

const webpack = require('webpack');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const path = require('path');

module.exports = {
	mode:   'development',
	target: 'web',
	entry:  {
		bundle: './index',
	},
	output: {
		filename: '[name].js',
		path:     path.resolve(__dirname, ''),
		// sourceMapFilename: '[file].map',
	},
	resolve: {
		modules: [
			'node_modules',
			path.resolve(__dirname, 'components'), // import './components/Component' -> import 'Component'
		],
		// alias: {
		// 	root: path.resolve(__dirname, ''),
		// },
		extensions: ['.js', '.jsx'],
	},
	devtool: 'eval',
	// devtool: 'inline-source-map',
	optimization: {
		minimize:     true,
		namedModules: true, // Module names instead of numbers - resolves the large diff problem.
		minimizer:    [
			new UglifyJsPlugin({
				uglifyOptions: {
					compress: true,
					mangle: true,
					output:   {
						comments: false,
						beautify: true,
						bracketize: true,
					},
					warnings: true,
				},
				// sourceMap: true,
			}),
		],
	},
	plugins: [
		new webpack.DefinePlugin({
			PROD: process.env.NODE_ENV === 'production',
		}),
		new webpack.HotModuleReplacementPlugin(),
	],
	module: {
		rules: [
			{
				test:    /\.jsx$/, // regexp for JSX files
				exclude: /node_modules/,
				use:     [ // order: from bottom to top
					{
						loader:  'babel-loader',
						options: {
							plugins: [ // order: from top to bottom
								'@babel/proposal-function-bind', // instead of stage 0
								'@babel/proposal-class-properties', // static defaultProps
								'@babel/transform-flow-strip-types',
								'react-hot-loader/babel',
							],
							presets: [ // order: from bottom to top
								'@babel/env',
								'@babel/react',
							],
						},
					},
					// 'eslint-loader', // show errors in the console
				],
			},
			{
				test:  /\.css$/,
				oneOf: [
					{
						test: /font-awesome/,
						use:  [
							'style-loader',
							'css-loader',
							path.resolve(__dirname, './fa-only-woff-loader.js'),
						],
					},
					{
						use: [
							'style-loader',
							'css-loader',
						],
					},
				],
			},
			{
				test: /\.woff2?$/, // font-awesome icons
				use:  'url-loader',
			},
		],
	},
	devServer: {
		port:     8081,
		hot:      true,
		compress: true,
	},
};
