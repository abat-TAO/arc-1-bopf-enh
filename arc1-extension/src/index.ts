import type { Plugin } from 'arc-1/public';
import { deleteTool } from './tools/delete.js';
import { maintainTool } from './tools/maintain.js';
import { readTool } from './tools/read.js';
import { writeTool } from './tools/write.js';

const plugin: Plugin = {
  name: 'bopf-enh',
  version: '0.1.0',
  apiVersion: 1,
  tools: [readTool, writeTool, deleteTool, maintainTool],
};

export default plugin;
