// Design Diff - Figma 디자인 변경 비교 플러그인
// 선택한 스크린의 히스토리를 저장하고 비교할 수 있습니다.

interface HistoryItem {
  id: string;
  nodeId: string;
  nodeName: string;
  timestamp: number;
  imageData: string; // base64 encoded image
  nodeData: SerializedNode;
}

interface SerializedNode {
  id: string;
  name: string;
  type: string;
  width: number;
  height: number;
  x: number;
  y: number;
}

// 플러그인 UI 표시 (3컬럼 레이아웃을 위해 넓게 설정)
figma.showUI(__html__, { 
  width: 1200, 
  height: 700,
  themeColors: true
});

// 현재 선택된 노드 추적
let currentSelectedNode: SceneNode | null = null;

// 선택된 노드의 이미지 내보내기
async function exportNodeAsImage(node: SceneNode): Promise<string> {
  try {
    const bytes = await node.exportAsync({
      format: 'PNG',
      constraint: { type: 'SCALE', value: 1 }
    });
    
    // Uint8Array를 base64로 변환
    const base64 = figma.base64Encode(bytes);
    return `data:image/png;base64,${base64}`;
  } catch (error) {
    console.error('이미지 내보내기 실패:', error);
    return '';
  }
}

// 노드 정보 직렬화
function serializeNode(node: SceneNode): SerializedNode {
  return {
    id: node.id,
    name: node.name,
    type: node.type,
    width: 'width' in node ? node.width : 0,
    height: 'height' in node ? node.height : 0,
    x: node.x,
    y: node.y
  };
}

// 히스토리 로드
async function loadHistory(nodeId: string): Promise<HistoryItem[]> {
  const key = `history_${nodeId}`;
  const data = await figma.clientStorage.getAsync(key);
  return data || [];
}

// 히스토리 저장
async function saveHistory(nodeId: string, history: HistoryItem[]): Promise<void> {
  const key = `history_${nodeId}`;
  // 최대 20개까지만 저장
  const trimmedHistory = history.slice(0, 20);
  await figma.clientStorage.setAsync(key, trimmedHistory);
}

// 스냅샷 생성
async function createSnapshot(node: SceneNode): Promise<HistoryItem> {
  const imageData = await exportNodeAsImage(node);
  const nodeData = serializeNode(node);
  
  return {
    id: `snapshot_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    nodeId: node.id,
    nodeName: node.name,
    timestamp: Date.now(),
    imageData,
    nodeData
  };
}

// 선택 변경 시 처리
async function handleSelectionChange() {
  const selection = figma.currentPage.selection;
  
  if (selection.length === 0) {
    currentSelectedNode = null;
    figma.ui.postMessage({ 
      type: 'selection-cleared'
    });
    return;
  }
  
  const node = selection[0];
  
  // Frame, Component, ComponentSet만 허용
  if (node.type !== 'FRAME' && node.type !== 'COMPONENT' && node.type !== 'COMPONENT_SET' && node.type !== 'INSTANCE') {
    figma.ui.postMessage({ 
      type: 'invalid-selection',
      message: 'Frame, Component 또는 Instance를 선택해주세요.'
    });
    return;
  }
  
  currentSelectedNode = node;
  
  // 현재 노드 이미지와 히스토리 로드
  const [currentImage, history] = await Promise.all([
    exportNodeAsImage(node),
    loadHistory(node.id)
  ]);
  
  figma.ui.postMessage({
    type: 'node-selected',
    data: {
      nodeId: node.id,
      nodeName: node.name,
      nodeType: node.type,
      currentImage,
      history
    }
  });
}

// 초기 로드 시 선택 확인
handleSelectionChange();

// 선택 변경 리스너
figma.on('selectionchange', handleSelectionChange);

// UI 메시지 처리
figma.ui.onmessage = async (msg: { type: string; [key: string]: unknown }) => {
  switch (msg.type) {
    case 'save-snapshot': {
      if (!currentSelectedNode) {
        figma.notify('스크린을 먼저 선택해주세요.', { error: true });
        return;
      }
      
      const snapshot = await createSnapshot(currentSelectedNode);
      const history = await loadHistory(currentSelectedNode.id);
      
      // 새 스냅샷을 맨 앞에 추가
      history.unshift(snapshot);
      await saveHistory(currentSelectedNode.id, history);
      
      figma.ui.postMessage({
        type: 'snapshot-saved',
        data: { history }
      });
      
      figma.notify('스냅샷이 저장되었습니다! 📸');
      break;
    }
    
    case 'delete-snapshot': {
      const snapshotId = msg.snapshotId as string;
      const nodeId = msg.nodeId as string;
      
      let history = await loadHistory(nodeId);
      history = history.filter(item => item.id !== snapshotId);
      await saveHistory(nodeId, history);
      
      figma.ui.postMessage({
        type: 'snapshot-deleted',
        data: { history }
      });
      
      figma.notify('스냅샷이 삭제되었습니다.');
      break;
    }
    
    case 'refresh-current': {
      if (currentSelectedNode) {
        const currentImage = await exportNodeAsImage(currentSelectedNode);
        figma.ui.postMessage({
          type: 'current-refreshed',
          data: { currentImage }
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
