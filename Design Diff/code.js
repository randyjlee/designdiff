// Design Diff - Figma 디자인 변경 비교 플러그인
// OAuth + Version History API
"use strict";

// 플러그인 UI 표시
figma.showUI(__html__, {
  width: 1000,
  height: 700,
  themeColors: true
});

// 저장된 토큰 로드
async function loadToken() {
  return await figma.clientStorage.getAsync('figma_access_token');
}

// 토큰 저장
async function saveToken(token) {
  await figma.clientStorage.setAsync('figma_access_token', token);
}

// 토큰 삭제
async function clearToken() {
  await figma.clientStorage.deleteAsync('figma_access_token');
}

// 선택된 노드의 이미지 내보내기
async function exportNodeAsImage(node) {
  try {
    const bytes = await node.exportAsync({
      format: 'PNG',
      constraint: { type: 'SCALE', value: 1 }
    });

    const base64 = figma.base64Encode(bytes);
    return `data:image/png;base64,${base64}`;
  } catch (error) {
    console.error('이미지 내보내기 실패:', error);
    return '';
  }
}

// 선택 변경 시 처리
async function handleSelectionChange() {
  const selection = figma.currentPage.selection;

  if (selection.length === 0) {
    figma.ui.postMessage({
      type: 'selection-cleared'
    });
    return;
  }

  const node = selection[0];

  // Frame, Component, ComponentSet, Instance만 허용
  if (node.type !== 'FRAME' && node.type !== 'COMPONENT' && node.type !== 'COMPONENT_SET' && node.type !== 'INSTANCE') {
    figma.ui.postMessage({
      type: 'invalid-selection',
      message: 'Frame, Component 또는 Instance를 선택해주세요.'
    });
    return;
  }

  const imageData = await exportNodeAsImage(node);

  figma.ui.postMessage({
    type: 'node-selected',
    data: {
      nodeId: node.id,
      nodeName: node.name,
      nodeType: node.type,
      imageData
    }
  });
}

// 초기화
async function init() {
  const token = await loadToken();
  const fileKey = figma.fileKey;
  
  figma.ui.postMessage({
    type: 'init',
    data: {
      token,
      fileKey
    }
  });
  
  handleSelectionChange();
}

init();

// 선택 변경 리스너
figma.on('selectionchange', handleSelectionChange);

// UI 메시지 처리
figma.ui.onmessage = async (msg) => {
  switch (msg.type) {
    case 'save-token': {
      await saveToken(msg.token);
      figma.notify('Connected to Figma! 🎉');
      
      figma.ui.postMessage({
        type: 'token-saved',
        data: { token: msg.token }
      });
      break;
    }
    
    case 'clear-token': {
      await clearToken();
      figma.notify('Disconnected from Figma');
      
      figma.ui.postMessage({
        type: 'token-cleared'
      });
      break;
    }
    
    case 'get-current-image': {
      const selection = figma.currentPage.selection;
      if (selection.length > 0) {
        const node = selection[0];
        const imageData = await exportNodeAsImage(node);
        figma.ui.postMessage({
          type: 'current-image',
          data: { 
            imageData,
            nodeId: node.id,
            nodeName: node.name
          }
        });
      }
      break;
    }

    case 'close': {
      figma.closePlugin();
      break;
    }
  }
};
