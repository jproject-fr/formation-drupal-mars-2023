<?php

namespace Drupal\hello\Plugin\Block;

use Drupal\Core\Block\BlockBase;

/**
 * Provides a hello block.
 *
 * @Block(
 *  id = "hello_block",
 *  admin_label = @Translation("Hello")
 * )

 */
class HelloBlock extends BlockBase {
  /**
   * Implements build function
   */
  public function build()
  {
    $items = ['item1', 'item2'];
    $list =  [
      '#theme' => 'item_list',
      '#items' => $items,
      '#title' => $this->t('My title'),
    ];
    return [
      'list' => $list,
    ];
  }
}
